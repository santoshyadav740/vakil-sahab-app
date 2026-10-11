import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

// ==============================================================
// 1. CONFIGURATION
// ==============================================================
const String GEMINI_API_KEY = "AQ.Ab8RN6JFc3skZ3wi5WMU3Q2dFSKW5EqKh7icy4AkwESEAjUuQwE";

// Aapka 6-Digit Master Activation PIN (Ise badal sakte hain)
const String MASTER_ACTIVATION_PIN = "571990"; 

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VakilAgentApp());
}

class VakilAgentApp extends StatelessWidget {
  const VakilAgentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vakil Sahab AI Agent',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F172A), // Slate Dark Legal Navy
          primary: const Color(0xFF0F172A),
        ),
      ),
      home: const LicenseLockScreen(),
    );
  }
}

// ==============================================================
// 2. 6-DIGIT LICENSE / ACTIVATION PIN SCREEN
// ==============================================================
class LicenseLockScreen extends StatefulWidget {
  const LicenseLockScreen({super.key});

  @override
  State<LicenseLockScreen> createState() => _LicenseLockScreenState();
}

class _LicenseLockScreenState extends State<LicenseLockScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _isChecking = true;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _checkExistingLicense();
  }

  Future<void> _checkExistingLicense() async {
    final prefs = await SharedPreferences.getInstance();
    final isActivated = prefs.getBool('is_app_activated') ?? false;

    if (isActivated) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LegalAgentDashboard()),
        );
      }
    } else {
      setState(() => _isChecking = false);
    }
  }

  Future<void> _verifyPin() async {
    final inputPin = _pinController.text.trim();
    if (inputPin == MASTER_ACTIVATION_PIN) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_app_activated', true);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LegalAgentDashboard()),
        );
      }
    } else {
      setState(() {
        _errorMessage = "Amanaya PIN! Kripya sahi 6-digit license key dalein.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B132B),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white10,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield_outlined, size: 64, color: Colors.amberAccent),
              ),
              const SizedBox(height: 24),
              const Text(
                "Advocate License Verification",
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Yeh app authorized use ke liye protected hai.\nKripya apna 6-Digit Activation PIN darj karein.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                obscureText: true,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 26, letterSpacing: 14, color: Colors.white, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  counterText: "",
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.08),
                  hintText: "••••••",
                  hintStyle: const TextStyle(color: Colors.white30, letterSpacing: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(_errorMessage, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _verifyPin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amberAccent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Unlock & Activate", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==============================================================
// 3. AUTONOMOUS LEGAL AI AGENT DASHBOARD
// ==============================================================
class LegalAgentDashboard extends StatefulWidget {
  const LegalAgentDashboard({super.key});

  @override
  State<LegalAgentDashboard> createState() => _LegalAgentDashboardState();
}

class _LegalAgentDashboardState extends State<LegalAgentDashboard> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _rawSpokenText = "";
  String _selectedLocale = "hi_IN"; // Hindi / English toggle

  bool _isAgentRunning = false;
  String _detectedMatter = "";
  String _agentDraftOutput = "";
  String _agentInsights = "";

  void _toggleMic() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      bool available = await _speech.initialize(
        onError: (e) => setState(() => _isListening = false),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          localeId: _selectedLocale,
          onResult: (result) {
            setState(() {
              _rawSpokenText = result.recognizedWords;
            });
          },
        );
      }
    }
  }

  // Autonomous Agent Workflow Execution
  Future<void> _runLegalAgent() async {
    if (_rawSpokenText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pehle microphone daba kar case ke facts bolein!")),
      );
      return;
    }

    setState(() {
      _isAgentRunning = true;
      _agentDraftOutput = "";
      _detectedMatter = "";
      _agentInsights = "";
    });

    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: GEMINI_API_KEY,
      );

      final agentSystemPrompt = '''
You are "Vakil Sahab AI Agent", an autonomous legal drafting assistant specialized in Indian Judiciary (District Courts, High Courts & Tribunals).

Your task is to analyze the provided raw dictated text and autonomously perform 3 tasks:
1. DETECT THE CASE MATTER: (e.g., Criminal Bail / Sec 138 NI Act / Civil Injunction / Domestic Violence / Revenue Application).
2. PROVIDE LEGAL CHECKLIST & INSIGHTS: Mention key statutory ingredients or missing timelines (limitation, mandatory notices, jurisdiction).
3. AUTONOMOUS COURT-READY DRAFT:
   - Proper Court Header Placeholder
   - Case Particulars (Petitioner/Applicant vs Respondent)
   - Facts in chronological, numbered paragraphs starting with "That..."
   - Substantive Grounds
   - Clear Prayer Clause.

FORMAT YOUR RESPONSE EXACTLY AS FOLLOWS (with these exact headers):
### MATTER:
[Name of detected matter and court type]

### AGENT INSIGHTS:
[Key statutory provisions & legal considerations]

### COURT DRAFT:
[Full structured ready-to-file legal draft]

Raw Dictated Facts:
$_rawSpokenText
''';

      final response = await model.generateContent([Content.text(agentSystemPrompt)]);
      final fullText = response.text ?? "";

      // Parse Agent Response Sections
      String matter = "Court Matter";
      String insights = "";
      String draft = fullText;

      if (fullText.contains("### MATTER:") && fullText.contains("### AGENT INSIGHTS:") && fullText.contains("### COURT DRAFT:")) {
        matter = fullText.split("### MATTER:")[1].split("### AGENT INSIGHTS:")[0].trim();
        insights = fullText.split("### AGENT INSIGHTS:")[1].split("### COURT DRAFT:")[0].trim();
        draft = fullText.split("### COURT DRAFT:")[1].trim();
      }

      setState(() {
        _detectedMatter = matter;
        _agentInsights = insights;
        _agentDraftOutput = draft;
        _isAgentRunning = false;
      });
    } catch (e) {
      setState(() => _isAgentRunning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Agent execution error: $e")),
      );
    }
  }

  void _shareViaWhatsApp() {
    if (_agentDraftOutput.isNotEmpty) {
      Share.share(_agentDraftOutput, subject: 'Court Legal Draft');
    }
  }

  void _copyDraft() {
    if (_agentDraftOutput.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _agentDraftOutput));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Draft clipboard par copy ho gaya!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("⚖️ Vakil Sahab AI Agent", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFF0F172A),
        actions: [
          DropdownButton<String>(
            value: _selectedLocale,
            dropdownColor: const Color(0xFF1E293B),
            underline: const SizedBox(),
            icon: const Icon(Icons.language, color: Colors.white),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            items: const [
              DropdownMenuItem(value: "hi_IN", child: Text("हिन्दी")),
              DropdownMenuItem(value: "en_IN", child: Text("English")),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _selectedLocale = val);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Voice Input Box
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      _isListening ? "🎙️ Sun rahe hain... (Tap to Pause)" : "Mic dabakar case ke facts bolein",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _isListening ? Colors.redAccent : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _toggleMic,
                      child: Container(
                        width: 75,
                        height: 75,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isListening ? Colors.redAccent : const Color(0xFF0F172A),
                        ),
                        child: Icon(_isListening ? Icons.stop : Icons.mic, color: Colors.white, size: 38),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _rawSpokenText.isEmpty ? "(Aapka bola hua text yahan aayega...)" : _rawSpokenText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _rawSpokenText.isEmpty ? Colors.grey : Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Autonomous Execute Agent Button
            ElevatedButton.icon(
              onPressed: _isAgentRunning ? null : _runLegalAgent,
              icon: _isAgentRunning
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.auto_awesome, color: Colors.white),
              label: Text(
                _isAgentRunning ? "AI Agent Analyze & Draft Kar Raha Hai..." : "⚡ Run Autonomous Legal Agent",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB), // Royal Blue
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),

            // Agent Detection & Insights
            if (_detectedMatter.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade400),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.policy, color: Colors.brown, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Detected: $_detectedMatter",
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.brown),
                          ),
                        ),
                      ],
                    ),
                    if (_agentInsights.isNotEmpty) ...[
                      const Divider(height: 16),
                      Text(
                        _agentInsights,
                        style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.4),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Final Draft Display
            if (_agentDraftOutput.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Final Legal Draft:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy, color: Color(0xFF0F172A)),
                        onPressed: _copyDraft,
                        tooltip: "Copy Draft",
                      ),
                      IconButton(
                        icon: const Icon(Icons.share, color: Colors.green),
                        onPressed: _shareViaWhatsApp,
                        tooltip: "WhatsApp / Share",
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SelectableText(
                  _agentDraftOutput,
                  style: const TextStyle(fontSize: 14, height: 1.5, fontFamily: 'monospace'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
