import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/athkar_model.dart';

class AthkarScreen extends StatefulWidget {
  final Athkar athkar;
  const AthkarScreen({super.key, required this.athkar});

  @override
  State<AthkarScreen> createState() => _AthkarScreenState();
}

class _AthkarScreenState extends State<AthkarScreen> {
  final AudioPlayer _player = AudioPlayer();
  int? _currentPlayingIndex;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  final Color primary = const Color(0xFF0F4C75);
  final Color secondary = const Color(0xFF3282B8);
  final Color bg = const Color(0xFFE8F7F5);
  final Color cardColor = Colors.white.withOpacity(0.85);

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _togglePlay(String url, int index) async {
    if (_currentPlayingIndex == index && _player.playing) {
      await _player.pause();
      setState(() {
        _currentPlayingIndex = null;
      });
    } else {
      try {
        setState(() {
          _currentPlayingIndex = index;
        });

        await _player.setUrl(url);
        await _player.play();

        _player.durationStream.listen((d) {
          if (d != null) {
            setState(() {
              _totalDuration = d;
            });
          }
        });

        _player.positionStream.listen((p) {
          setState(() {
            _currentPosition = p;
          });
        });

        _player.playerStateStream.listen((state) {
          if (state.processingState == ProcessingState.completed) {
            setState(() {
              _currentPlayingIndex = null;
              _currentPosition = Duration.zero;
            });
          }
        });
      } catch (e) {
        print('خطأ أثناء تشغيل الصوت: $e');
      }
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(d.inMinutes)}:${twoDigits(d.inSeconds % 60)}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: primary,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'حصن المسلم',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          // عنوان القسم تحت AppBar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: secondary,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              widget.athkar.category,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),

          // قائمة الأذكار
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.athkar.array.length,
              itemBuilder: (context, index) {
                final thikr = widget.athkar.array[index];
                final audioUrl =
                    'https://raw.githubusercontent.com/rn0x/Adhkar-json/main${thikr.audio}';
                final isCurrent = _currentPlayingIndex == index && _player.playing;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [cardColor, cardColor.withOpacity(0.95)],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        thikr.text,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.8,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CircleAvatar(
                            backgroundColor: primary,
                            child: IconButton(
                              icon: Icon(
                                isCurrent ? Icons.pause : Icons.play_arrow,
                                color: Colors.white,
                              ),
                              onPressed: () => _togglePlay(audioUrl, index),
                            ),
                          ),
                          Text(
                            'عدد التكرار: ${thikr.count}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),

                      // شريط التقدم عند التشغيل
                      if (isCurrent)
                        Column(
                          children: [
                            Slider(
                              value: _currentPosition.inSeconds.toDouble(),
                              max: _totalDuration.inSeconds.toDouble(),
                              onChanged: (value) async {
                                final pos = Duration(seconds: value.toInt());
                                await _player.seek(pos);
                              },
                              activeColor: primary,
                              inactiveColor: primary.withOpacity(0.3),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_formatDuration(_currentPosition),
                                    style: TextStyle(fontSize: 12)),
                                Text(_formatDuration(_totalDuration),
                                    style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
