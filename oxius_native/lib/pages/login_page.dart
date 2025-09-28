import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/translation_service.dart';
import '../services/banner_service.dart';
import '../widgets/footer.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  late ScrollController _scrollController;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final TranslationService _ts = TranslationService();
  final BannerService _bannerService = BannerService();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  String _errorMessage = '';
  bool _loadingLogo = true;
  Map<String, dynamic>? _logoData;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _loadLogo();
    _bannerService.loadBanners();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final authResponse = await AuthService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        if (authResponse != null) {
          // Clear any existing error
          setState(() {
            _errorMessage = '';
          });
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    _ts.t('login_success', fallback: 'Welcome back, ${authResponse.user.displayName}!'),
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
              backgroundColor: Colors.purple.shade600,
              duration: const Duration(seconds: 2),
            ),
          );

          // Wait a moment for the user to see the success message
          await Future.delayed(const Duration(milliseconds: 500));
          
          // Navigate back to home page
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/');
          }
        } else {
          setState(() {
            _errorMessage = 'Login failed. Please try again.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '').replaceFirst('Login error: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadLogo() async {
    try {
      // Simulate loading logo from API
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
          _logoData = {
            'image': '/static/frontend/images/logo.png',
            'alt': 'App Logo',
          };
          _loadingLogo = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingLogo = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              controller: _scrollController,
              slivers: [
              SliverToBoxAdapter(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth > 768;
                    
                    if (isDesktop) {
                      // Desktop/Tablet layout - two columns
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                        child: Row(
                          children: [
                            // Left side - Image (3/5 width)
                            Expanded(
                              flex: 3,
                              child: Container(
                                height: 500,
                                margin: const EdgeInsets.only(right: 32),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  image: const DecorationImage(
                                    image: NetworkImage('http://127.0.0.1:8000/static/frontend/images/register.webp'),
                                    fit: BoxFit.cover,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Right side - Form (2/5 width)
                            Expanded(
                              flex: 2,
                              child: _buildLoginForm(),
                            ),
                          ],
                        ),
                      );
                    } else {
                      // Mobile layout - single column
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildLoginForm(),
                      );
                    }
                  },
                ),
              ),
              
              // Banner below login form
              SliverToBoxAdapter(
                child: _buildBannerSection(),
              ),
              
              const SliverToBoxAdapter(child: AppFooter()),
            ],
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Form Header
            Column(
              children: [
                // Logo
                _buildLogo(),
                const SizedBox(height: 24),
                
                Text(
                  _ts.t('welcome_back', fallback: 'Welcome Back'),
                  style: GoogleFonts.roboto(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _ts.t('login_subtitle', fallback: 'Sign in to your account'),
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Error message
            if (_errorMessage.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            
            // Email Field
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: _ts.t('email_address', fallback: 'Email address'),
                    prefixIcon: Icon(Icons.email_outlined, color: Colors.grey.shade400, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.purple.shade500, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.red.shade400),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.red.shade400, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return _ts.t('email_required', fallback: 'Email is required');
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return _ts.t('email_invalid', fallback: 'Please enter a valid email');
                    }
                    return null;
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Password Field
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: _ts.t('password', fallback: 'Password'),
                    prefixIcon: Icon(Icons.lock_outline, color: Colors.grey.shade400, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.purple.shade500, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.red.shade400),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.red.shade400, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return _ts.t('password_required', fallback: 'Password is required');
                    }
                    return null;
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Remember me and Forgot password
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SizedBox(
                      height: 20,
                      width: 20,
                      child: Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value ?? false;
                          });
                        },
                        activeColor: Colors.purple.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _ts.t('remember_me', fallback: 'Remember me'),
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to forgot password
                  },
                  child: Text(
                    _ts.t('forgot_password', fallback: 'Forgot password?'),
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: Colors.purple.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Login Button
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade600,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  disabledBackgroundColor: Colors.purple.shade300,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.login, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _ts.t('sign_in', fallback: 'Sign In'),
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Sign Up Link
            Center(
              child: TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _ts.t('registration_coming_soon', 
                              fallback: 'Registration feature coming soon!')),
                    ),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_add_outlined, size: 16, color: Colors.purple.shade600),
                    const SizedBox(width: 4),
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.roboto(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(
                            text: _ts.t('dont_have_account', fallback: "Don't have an account? "),
                          ),
                          TextSpan(
                            text: 'Sign Up',
                            style: TextStyle(
                              color: Colors.purple.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    if (_loadingLogo) {
      return const SizedBox(
        height: 48,
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (_logoData != null) {
      return Image.network(
        'http://127.0.0.1:8000${_logoData!['image']}',
        height: 48,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            'assets/images/logo.png',
            height: 48,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 48,
                width: 150,
                decoration: BoxDecoration(
                  color: Colors.purple.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'LOGO',
                    style: GoogleFonts.roboto(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade600,
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    } else {
      return Container(
        height: 48,
        width: 150,
        decoration: BoxDecoration(
          color: Colors.purple.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            'LOGO',
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade600,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildBannerSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        children: [
          if (_bannerService.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_bannerService.banners.isNotEmpty)
            SizedBox(
              height: 200,
              child: PageView.builder(
                itemCount: _bannerService.banners.length,
                itemBuilder: (context, index) {
                  final banner = _bannerService.banners[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          // Banner Image
                          banner['image'] != null
                              ? Image.network(
                                  banner['image'],
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: double.infinity,
                                      height: 200,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.purple.shade400,
                                            Colors.blue.shade400,
                                          ],
                                        ),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.image,
                                          color: Colors.white,
                                          size: 48,
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  width: double.infinity,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.purple.shade400,
                                        Colors.blue.shade400,
                                      ],
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.image,
                                      color: Colors.white,
                                      size: 48,
                                    ),
                                  ),
                                ),
                          
                          // Banner Text Overlay
                          if (banner['title'] != null)
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.7),
                                    ],
                                  ),
                                ),
                                child: Text(
                                  banner['title'],
                                  style: GoogleFonts.roboto(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            )
          else
            // Default banner when no banners loaded
            Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.shade400,
                    Colors.blue.shade400,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.campaign,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _ts.t('welcome_banner', fallback: 'Welcome to our platform!'),
                      style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _ts.t('banner_subtitle', fallback: 'Join us today and explore amazing features'),
                      style: GoogleFonts.roboto(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}