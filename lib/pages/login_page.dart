import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../navigation/main_navigation.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool isLoading = true;
  bool _isButtonPressed = false;
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut),
    );
    _checkSession();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    final supabase = Supabase.instance.client;

    if (supabase.auth.currentUser == null) {
      try {
        await supabase.auth.signInAnonymously();
      } catch (e) {
        debugPrint('Anonymous sign-in failed: $e');
      }
    }

    if (username != null && username.isNotEmpty) {
      _goToHome();
    } else {
      setState(() => isLoading = false);
      _animationController?.forward();
    }
  }

  Future<void> _saveUsernameAndContinue() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;

    setState(() => _isButtonPressed = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', name);

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user != null) {
      try {
        await supabase.from('user_profiles').upsert({
          'id': user.id,
          'username': name,
          'level': 1
        });
      } catch (e) {
        debugPrint('Failed to upsert user profile: $e');
      }
    }

    await Future.delayed(const Duration(milliseconds: 300));
    _goToHome();
  }

  void _goToHome() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigation()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      // Automatically pushes content up when keyboard appears
      resizeToAvoidBottomInset: true, 
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : GestureDetector(
              // Closes keyboard if user taps on the background
              onTap: () => FocusScope.of(context).unfocus(),
              child: FadeTransition(
                opacity: _fadeAnimation ?? const AlwaysStoppedAnimation(1.0),
                child: SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.08,
                          vertical: 20,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            // Forces content to fill the screen height for centering
                            minHeight: constraints.maxHeight - 40, 
                          ),
                          child: IntrinsicHeight(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Logo
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.1),
                                        blurRadius: 35,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: Image.asset(
                                    'assets/icons/logo.png',
                                    height: screenHeight * 0.12,
                                  ),
                                ),
                                
                                SizedBox(height: screenHeight * 0.05),
                                
                                // Welcome Text
                                ShaderMask(
                                  shaderCallback: (bounds) => const LinearGradient(
                                    colors: [Colors.white, Colors.white70],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ).createShader(bounds),
                                  child: const Text(
                                    'Welcome to WiFi Pulse',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w300,
                                      letterSpacing: 1.2,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                
                                const SizedBox(height: 12),
                                
                                // Subtitle
                                Text(
                                  'Enter your display name',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withOpacity(0.6),
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: 0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                
                                SizedBox(height: screenHeight * 0.06),
                                
                                // Input Field
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _focusNode.hasFocus 
                                          ? const Color(0xFF266991)
                                          : const Color(0xFF266991).withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _controller,
                                    focusNode: _focusNode,
                                    onChanged: (value) => setState(() {}),
                                    style: const TextStyle(color: Colors.white, fontSize: 16),
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: const Color(0xFF1A1A1A),
                                      hintText: 'Your name',
                                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                    ),
                                  ),
                                ),
                                
                                SizedBox(height: screenHeight * 0.04),
                                
                                // Continue Button
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: double.infinity,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: _controller.text.trim().isNotEmpty
                                        ? LinearGradient(
                                            colors: [
                                              Colors.white.withOpacity(0.9),
                                              Colors.white.withOpacity(0.8),
                                            ],
                                          )
                                        : LinearGradient(
                                            colors: [
                                              Colors.white.withOpacity(0.2),
                                              Colors.white.withOpacity(0.1),
                                            ],
                                          ),
                                    boxShadow: _controller.text.trim().isNotEmpty
                                        ? [BoxShadow(color: Colors.white.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))]
                                        : [],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _controller.text.trim().isNotEmpty && !_isButtonPressed
                                          ? _saveUsernameAndContinue
                                          : null,
                                      borderRadius: BorderRadius.circular(16),
                                      child: Center(
                                        child: _isButtonPressed
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                                              )
                                            : Text(
                                                'Continue',
                                                style: TextStyle(
                                                  color: _controller.text.trim().isNotEmpty ? Colors.black : Colors.white38,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Bottom padding to ensure the button is visible above keyboard
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
    );
  }
}