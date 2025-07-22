import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart';

void main() {
  runApp(const SalesTrainerApp());
}

class SalesTrainerApp extends StatelessWidget {
  const SalesTrainerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Sales Trainer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(),
      ),
      home: const SalesTrainerHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SalesTrainerHomePage extends StatefulWidget {
  const SalesTrainerHomePage({super.key});

  @override
  State<SalesTrainerHomePage> createState() => _SalesTrainerHomePageState();
}

class _SalesTrainerHomePageState extends State<SalesTrainerHomePage> {
  String? selectedProduct;
  final List<String> productTypes = [
    'Shoes',
    'Software',
    'Fitness Program',
    'Insurance',
    'Other',
  ];
  bool isRecording = false;
  String transcript = '';
  String suggestion = 'Your suggested reply will appear here.';
  String conversationDirection = 'General';
  bool _isLoadingSuggestion = false;
  bool _isPlayingAudio = false;

  late stt.SpeechToText _speech;
  bool _speechAvailable = false;
  late FlutterTts _flutterTts;

  Future<void> _fetchSuggestion() async {
    if (transcript.isEmpty) return;
    
    setState(() {
      _isLoadingSuggestion = true;
      suggestion = 'Thinking...';
    });
    
    try {
      // Check if OpenAI is enabled
      if (!Config.enableOpenAI) {
        setState(() {
          suggestion = 'AI suggestions are currently disabled.';
        });
        return;
      }
      
      final apiKey = Config.openAIKey;
      final prompt =
          'You are a smart sales assistant. The salesperson is selling: '
          '${selectedProduct ?? 'Unknown'}'
          '\nConversation direction: $conversationDirection'
          '\nCustomer said: "$transcript"'
          '\nSuggest a custom, concise reply for the salesperson to say next.';
      
      final response = await http.post(
        Uri.parse('${Config.openAIBaseUrl}/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {'role': 'system', 'content': 'You are a helpful sales assistant.'},
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 80,
          'temperature': 0.7,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['choices'][0]['message']['content']?.trim();
        setState(() {
          suggestion = reply ?? 'No suggestion found.';
        });
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        setState(() {
          suggestion = 'Failed to get suggestion. Please check your API key.';
        });
      }
    } catch (e) {
      print('Error fetching suggestion: $e');
      setState(() {
        suggestion = 'Error: Unable to connect to AI service.';
      });
    } finally {
      setState(() {
        _isLoadingSuggestion = false;
      });
    }
  }

  Future<void> _playSuggestion() async {
    if (suggestion.isEmpty || suggestion == 'Your suggested reply will appear here.' || 
        suggestion == 'Thinking...' || suggestion == 'Failed to get suggestion.' || 
        suggestion.startsWith('Error:')) {
      print('TTS: No valid suggestion to play.');
      return;
    }
    setState(() {
      _isPlayingAudio = true;
    });
    try {
      print('TTS: Speaking suggestion: $suggestion');
      await _flutterTts.awaitSpeakCompletion(true);
      var result = await _flutterTts.speak(suggestion);
      print('TTS: Speak result: $result');
    } catch (e) {
      print('Error playing audio: $e');
    } finally {
      setState(() {
        _isPlayingAudio = false;
      });
    }
  }

  Future<void> _stopAudio() async {
    await _flutterTts.stop();
    setState(() {
      _isPlayingAudio = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _initSpeech();
    _initTts();
    _printTtsDebugInfo();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    
    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isPlayingAudio = false;
      });
    });
    
    _flutterTts.setErrorHandler((msg) {
      setState(() {
        _isPlayingAudio = false;
      });
      print("TTS Error: $msg");
    });
  }

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onStatus: (status) {
          print('Speech status: $status');
        },
        onError: (error) {
          print('Speech error: $error');
        },
      );
      setState(() {});
    } catch (e) {
      print('Error initializing speech: $e');
      _speechAvailable = false;
      setState(() {});
    }
  }

  Future<void> _printTtsDebugInfo() async {
    var languages = await _flutterTts.getLanguages;
    print('TTS: Available languages: $languages');
    var voices = await _flutterTts.getVoices;
    print('TTS: Available voices: $voices');
  }

  Future<void> _testTts() async {
    setState(() {
      _isPlayingAudio = true;
    });
    try {
      print('TTS: Speaking test string');
      await _flutterTts.awaitSpeakCompletion(true);
      var result = await _flutterTts.speak('Hello, this is a test');
      print('TTS: Test speak result: $result');
    } catch (e) {
      print('TTS: Error during test: $e');
    } finally {
      setState(() {
        _isPlayingAudio = false;
      });
    }
  }

  void _startListening() async {
    if (!_speechAvailable) return;
    setState(() {
      isRecording = true;
      transcript = '';
    });
    await _speech.listen(
      onResult: (result) {
        setState(() {
          transcript = result.recognizedWords;
        });
      },
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
      ),
    );
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() {
      isRecording = false;
    });
    await _fetchSuggestion();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Sales Trainer'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  Scaffold.of(context).appBarMaxHeight!.toDouble() - 40, // 40 for padding
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Product selection dropdown
                  Text('Select Product Type',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedProduct,
                    items: productTypes
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedProduct = value;
                      });
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Audio recorder widget (placeholder)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isRecording ? 'Listening...' : 'Tap mic to start listening',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      IconButton(
                        icon:
                            Icon(isRecording ? Icons.mic : Icons.mic_none, size: 32),
                        color: isRecording ? Colors.red : Colors.grey[700],
                        onPressed: _speechAvailable
                            ? () {
                                if (isRecording) {
                                  _stopListening();
                                } else {
                                  _startListening();
                                }
                              }
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Live transcript (placeholder)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    height: 60,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        transcript.isEmpty
                            ? 'Live transcript will appear here.'
                            : transcript,
                        style: GoogleFonts.inter(fontSize: 16, color: Colors.black87),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Conversation direction buttons
                  Text('Steer Conversation',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    children: [
                      ChoiceChip(
                        label: const Text('General'),
                        selected: conversationDirection == 'General',
                        onSelected: (_) =>
                            setState(() => conversationDirection = 'General'),
                      ),
                      ChoiceChip(
                        label: const Text('Pitch Price'),
                        selected: conversationDirection == 'Pitch Price',
                        onSelected: (_) =>
                            setState(() => conversationDirection = 'Pitch Price'),
                      ),
                      ChoiceChip(
                        label: const Text('Features'),
                        selected: conversationDirection == 'Features',
                        onSelected: (_) =>
                            setState(() => conversationDirection = 'Features'),
                      ),
                      ChoiceChip(
                        label: const Text('Emotional Benefits'),
                        selected: conversationDirection == 'Emotional Benefits',
                        onSelected: (_) => setState(
                            () => conversationDirection = 'Emotional Benefits'),
                      ),
                      ChoiceChip(
                        label: const Text('Handle Objection'),
                        selected: conversationDirection == 'Handle Objection',
                        onSelected: (_) => setState(
                            () => conversationDirection = 'Handle Objection'),
                      ),
                      ChoiceChip(
                        label: const Text('Close Sale'),
                        selected: conversationDirection == 'Close Sale',
                        onSelected: (_) =>
                            setState(() => conversationDirection = 'Close Sale'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Suggestion box
                  Text('Suggested Reply',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.deepPurple[100]!),
                    ),
                    child: _isLoadingSuggestion
                        ? Row(
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              const SizedBox(width: 12),
                              Text('Thinking...',
                                  style: GoogleFonts.inter(fontSize: 18)),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      suggestion,
                                      style: GoogleFonts.inter(
                                          fontSize: 18, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  IconButton(
                                    icon: Icon(
                                      _isPlayingAudio ? Icons.stop : Icons.play_arrow,
                                      color: Colors.deepPurple,
                                      size: 28,
                                    ),
                                    onPressed: _isPlayingAudio 
                                        ? _stopAudio 
                                        : _playSuggestion,
                                  ),
                                ],
                              ),
                              if (suggestion != 'Your suggested reply will appear here.' &&
                                  suggestion != 'Thinking...' &&
                                  suggestion != 'Failed to get suggestion.' &&
                                  !suggestion.startsWith('Error:'))
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'Tap the play button to hear this reply',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.deepPurple[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  ),
                  const Spacer(),
                  // Save conversation button (placeholder)
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.save),
                    label: const Text('Save Conversation'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle:
                          const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _testTts,
                    icon: const Icon(Icons.volume_up),
                    label: const Text('Test TTS'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
