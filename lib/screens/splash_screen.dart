import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  bool _checkingSession = true;

  @override
  void initState() {
    super.initState();
    _checkReturningUser();
  }

  Future<void> _checkReturningUser() async {
    final prefs = await SharedPreferences.getInstance();
    final hasFavorites = (prefs.getStringList('favorite_teams') ?? []).isNotEmpty;
    if (mounted) {
      setState(() {
        _checkingSession = false;
      });
      if (hasFavorites) {
        // Returning user flow if desired
      }
    }
  }

  void _onGetStarted() {
    Navigator.pushNamed(context, '/onboarding');
  }

  void _onSignIn() {
    Navigator.pushNamed(context, '/auth');
  }

  void _onExploreAsGuest() {
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _checkingSession
            ? const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primary,
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                child: Column(
                  children: [
                    const Spacer(flex: 2),

                    // Minimal Brand Logo Mark
                    SvgPicture.asset(
                      'assets/svg/SportSphere_logo.svg',
                      width: 96,
                      height: 96,
                    ),
                    const SizedBox(height: 32),

                    // Micro Tagline / Brand Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.paleGreen,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: const Text(
                        'WELCOME TO SPORTSPHERE',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    const Text(
                      'Your Game,\nYour Score',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.text,
                        height: 1.15,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Minimal Subtitle
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Real-time scores, schedules, and breaking news for your favorite leagues and teams.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.muted,
                          height: 1.45,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Sleek, Minimal Inline Feature Tags
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildMinimalTag('assets/svg/ic_live.svg', 'Live Scores'),
                        _buildMinimalTag('assets/svg/ic_fixtures.svg', 'Fixtures'),
                        _buildMinimalTag('assets/svg/ic_news.svg', 'Latest News'),
                      ],
                    ),

                    const Spacer(flex: 3),

                    // Action Buttons
                    Column(
                      children: [
                        // Primary CTA: Get Started
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton(
                            onPressed: _onGetStarted,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Get Started',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                  Iconsax.arrow_right_1,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Secondary CTA: Sign In
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            onPressed: _onSignIn,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: AppTheme.outline,
                                width: 1.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.text,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Guest Mode Link
                        TextButton(
                          onPressed: _onExploreAsGuest,
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.muted,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          ),
                          child: const Text(
                            'Explore as Guest',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildMinimalTag(String svgPath, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.outline.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            svgPath,
            width: 13,
            height: 13,
            colorFilter: const ColorFilter.mode(
              AppTheme.primary,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.text,
            ),
          ),
        ],
      ),
    );
  }
}
