import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;
import 'package:just_audio/just_audio.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class SurahScreen extends StatefulWidget {
  final int surahNumber;
  const SurahScreen({required this.surahNumber, super.key});

  @override
  State<SurahScreen> createState() => _SurahScreenState();
}

class _SurahScreenState extends State<SurahScreen> {
  late AudioPlayer _audioPlayer;
  bool isPlaying = false;
  bool isLoading = false;

  final Color primary = const Color(0xFF0F4C75);
  final Color secondary = const Color(0xFF3282B8);

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    // عند انتهاء السورة يرجع للمثلث
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        setState(() => isPlaying = false);
        WakelockPlus.disable();
      }
    });
  }

  Future<void> toggleAudio() async {
    final url =
        "https://server8.mp3quran.net/afs/${widget.surahNumber.toString().padLeft(3, '0')}.mp3";

    if (isPlaying) {
      await _audioPlayer.pause();
      setState(() {
        isPlaying = false; // تغيير الأيقونة فورًا
        isLoading = false;
      });
      WakelockPlus.disable();
      return;
    }

    setState(() {
      isPlaying = true; // تحويل الأيقونة فورًا إلى "تساوي"
      isLoading = true;
    });

    try {
      await _audioPlayer.setAudioSource(
        ProgressiveAudioSource(Uri.parse(url)),
        preload: true,
      );
      await _audioPlayer.play();

      setState(() {
        isLoading = false; // انتهى التحميل
      });

      WakelockPlus.enable();

    } catch (e) {
      print("Error: $e");
      setState(() {
        isPlaying = false; // رجوع الأيقونة للمثلث عند الخطأ
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: secondary,
      appBar: AppBar(
        backgroundColor: primary,
        centerTitle: true,
        title: Text(
          quran.getSurahNameArabic(widget.surahNumber),
          style: GoogleFonts.amiri(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F4C75), Color(0xFF3282B8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: quran.getVerseCount(widget.surahNumber),
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white.withOpacity(0.85),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      quran.getVerse(
                        widget.surahNumber,
                        index + 1,
                        verseEndSymbol: true,
                      ),
                      textAlign: TextAlign.right,
                      style: GoogleFonts.amiri(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: primary,
                      ),
                    ),
                  );
                },
              ),
            ),

            // زر التشغيل/الإيقاف
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: FloatingActionButton(
                backgroundColor: primary,
                onPressed: toggleAudio,
                child: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  size: 32,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
