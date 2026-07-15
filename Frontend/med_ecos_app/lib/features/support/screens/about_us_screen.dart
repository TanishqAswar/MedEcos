import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class AboutUsScreen extends StatefulWidget {
  const AboutUsScreen({super.key});

  @override
  State<AboutUsScreen> createState() => _AboutUsScreenState();
}

class _AboutUsScreenState extends State<AboutUsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging || _tabController.index != _selectedTabIndex) {
        setState(() {
          _selectedTabIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Hero Banner with Logo & Tagline ──
          SliverAppBar(
            expandedHeight: isWide ? 340 : 380,
            pinned: true,
            backgroundColor: AppColors.primaryDark,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Back',
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF004D40),
                      Color(0xFF00796B),
                      Color(0xFF009688),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative circular glows
                    Positioned(
                      top: -60,
                      right: -60,
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -40,
                      left: -40,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.06),
                        ),
                      ),
                    ),
                    // Content
                    Center(
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24.0,
                            vertical: 40.0,
                          ),
                          child: isWide
                              ? ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 1060),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        flex: 6,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 14,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.18),
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: Colors.white.withOpacity(0.3),
                                                ),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.verified_user_rounded,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'THE MEDECOS STORY & VISION',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      letterSpacing: 1.2,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 18),
                                            const Text(
                                              'MedEcos',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 44,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              'Connecting Patients, Doctors, Pharmacists & Diagnostic Labs in One Intelligent Healthcare Continuum.',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.92),
                                                fontSize: 17,
                                                height: 1.45,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                            const SizedBox(height: 18),
                                            Wrap(
                                              spacing: 12,
                                              runSpacing: 8,
                                              children: [
                                                _buildHeroChip(Icons.lock, '100% Data Sovereignty'),
                                                _buildHeroChip(Icons.groups, 'Interprofessional Collaboration'),
                                                _buildHeroChip(Icons.smart_toy, 'Vaidya AI Companion'),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 48),
                                      Expanded(
                                        flex: 4,
                                        child: Center(
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Container(
                                                width: 170,
                                                height: 170,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.white.withOpacity(0.1),
                                                ),
                                              ),
                                              Container(
                                                width: 140,
                                                height: 140,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withOpacity(0.3),
                                                      blurRadius: 24,
                                                      offset: const Offset(0, 10),
                                                    ),
                                                  ],
                                                  border: Border.all(
                                                    color: Colors.white,
                                                    width: 4,
                                                  ),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(70),
                                                  child: Image.asset(
                                                    'assets/Icon.jpeg',
                                                    width: 140,
                                                    height: 140,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.18),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.verified_user_rounded,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'THE MEDECOS STORY & VISION',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    // Logo with glowing border
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.25),
                                            blurRadius: 20,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 3,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(50),
                                        child: Image.asset(
                                          'assets/Icon.jpeg',
                                          width: 88,
                                          height: 88,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'MedEcos',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 34,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 640),
                                      child: Text(
                                        'Connecting Patients, Doctors, Pharmacists & Diagnostic Labs in One Intelligent Healthcare Continuum.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.92),
                                          fontSize: 14,
                                          height: 1.4,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                color: Colors.white,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: !isWide,
                      indicatorColor: AppColors.primary,
                      indicatorWeight: 3.5,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textSecondary,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                      tabs: const [
                        Tab(
                          icon: Icon(Icons.flag_rounded, size: 20),
                          text: 'Our Goal & Aim',
                        ),
                        Tab(
                          icon: Icon(Icons.auto_awesome_rounded, size: 20),
                          text: 'Abstract Features',
                        ),
                        Tab(
                          icon: Icon(Icons.shield_rounded, size: 20),
                          text: 'Terms & Policies',
                        ),
                        Tab(
                          icon: Icon(Icons.hub_rounded, size: 20),
                          text: 'Ecosystem Roles',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Tab Views Content ──
          SliverFillRemaining(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildGoalAndAimSection(isWide),
                  _buildAbstractFeaturesSection(isWide),
                  _buildTermsAndPoliciesSection(isWide),
                  _buildEcosystemRolesSection(isWide),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 1. GOAL & AIM SECTION
  // ─────────────────────────────────────────────────────────────
  Widget _buildGoalAndAimSection(bool isWide) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionHeader(
                title: 'Visionary Purpose',
                subtitle:
                    'Why MedEcos exists and where we are steering the future of connected healthcare.',
              ),
              const SizedBox(height: 28),

              // Responsive Cards for Goal and Aim
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildVisionCard(
                        icon: Icons.emoji_events_rounded,
                        iconColor: const Color(0xFFE65100),
                        badgeText: 'OUR GOAL',
                        badgeColor: const Color(0xFFFFF3E0),
                        title: 'Democratizing Connected Healthcare',
                        description:
                            'Our goal is to eliminate fragmented, paper-heavy medical friction by building a unified, intelligent, and compassionate digital health ecosystem. We strive to make comprehensive healthcare management seamless, transparent, and instantly accessible to everyone—regardless of where they are.',
                        highlights: [
                          'Eliminate paper silos & lost prescriptions',
                          'Bring AI-driven clarity to medical data',
                          'Foster trust across the patient journey',
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _buildVisionCard(
                        icon: Icons.track_changes_rounded,
                        iconColor: const Color(0xFF00695C),
                        badgeText: 'OUR AIM',
                        badgeColor: const Color(0xFFE0F2F1),
                        title: 'Lifelong Patient Empowerment',
                        description:
                            'Our aim is to empower individuals with complete, lifelong sovereignty over their personal health records, while establishing real-time collaborative bridges between patients, doctors, pharmacists, and diagnostic laboratories. Every decision should be informed, timely, and secure.',
                        highlights: [
                          'Absolute patient ownership of records',
                          'Real-time interprofessional collaboration',
                          'Zero-delay prescription & lab fulfillment',
                        ],
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    _buildVisionCard(
                      icon: Icons.emoji_events_rounded,
                      iconColor: const Color(0xFFE65100),
                      badgeText: 'OUR GOAL',
                      badgeColor: const Color(0xFFFFF3E0),
                      title: 'Democratizing Connected Healthcare',
                      description:
                          'Our goal is to eliminate fragmented, paper-heavy medical friction by building a unified, intelligent, and compassionate digital health ecosystem. We strive to make comprehensive healthcare management seamless, transparent, and instantly accessible to everyone—regardless of where they are.',
                      highlights: [
                        'Eliminate paper silos & lost prescriptions',
                        'Bring AI-driven clarity to medical data',
                        'Foster trust across the patient journey',
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildVisionCard(
                      icon: Icons.track_changes_rounded,
                      iconColor: const Color(0xFF00695C),
                      badgeText: 'OUR AIM',
                      badgeColor: const Color(0xFFE0F2F1),
                      title: 'Lifelong Patient Empowerment',
                      description:
                          'Our aim is to empower individuals with complete, lifelong sovereignty over their personal health records, while establishing real-time collaborative bridges between patients, doctors, pharmacists, and diagnostic laboratories. Every decision should be informed, timely, and secure.',
                      highlights: [
                        'Absolute patient ownership of records',
                        'Real-time interprofessional collaboration',
                        'Zero-delay prescription & lab fulfillment',
                      ],
                    ),
                  ],
                ),

              const SizedBox(height: 40),
              _buildInspirationalQuoteBanner(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisionCard({
    required IconData icon,
    required Color iconColor,
    required String badgeText,
    required Color badgeColor,
    required String title,
    required String description,
    required List<String> highlights,
  }) {
    return _ExpandableVisionCard(
      icon: icon,
      iconColor: iconColor,
      badgeText: badgeText,
      badgeColor: badgeColor,
      title: title,
      description: description,
      highlights: highlights,
    );
  }

  Widget _buildInspirationalQuoteBanner() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryLight.withOpacity(0.4), AppColors.surfaceVariant],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '"Healthcare should never feel fragmented or overwhelming."',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'By bridging technology with compassion, MedEcos ensures that doctors have the clarity they need and patients have the peace of mind they deserve.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary.withOpacity(0.8),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 2. ABSTRACT FEATURES SECTION
  // ─────────────────────────────────────────────────────────────
  Widget _buildAbstractFeaturesSection(bool isWide) {
    final features = [
      {
        'title': 'Lifelong Digital Health Vault',
        'subtitle': 'Secure & Organized Repository',
        'desc':
            'A unified, lifelong digital locker that safely preserves prescriptions, diagnostic reports, imaging, and vaccination histories—accessible anytime, anywhere.',
        'icon': Icons.folder_special_rounded,
        'color': const Color(0xFF00897B),
      },
      {
        'title': 'Intelligent Record Digitization',
        'subtitle': 'Instant Visual Conversion',
        'desc':
            'Effortlessly transform physical prescriptions and handwritten medical notes into clear, structured schedules and actionable digital summaries with a single scan.',
        'icon': Icons.document_scanner_rounded,
        'color': const Color(0xFF1976D2),
      },
      {
        'title': 'Vaidya — AI Health Companion',
        'subtitle': '24/7 Conversational Guidance',
        'desc':
            'An intelligent, compassionate digital assistant ready to explain complex medical terminology, clarify medication timing, and provide dependable wellness guidance.',
        'icon': Icons.psychology_rounded,
        'color': const Color(0xFF7B1FA2),
      },
      {
        'title': 'Interactive Specialist Directory',
        'subtitle': 'Verified Healthcare Discovery',
        'desc':
            'Location-aware discovery connecting patients with verified physicians, specialized clinics, and diagnostic laboratories tailored to specific healthcare needs.',
        'icon': Icons.map_rounded,
        'color': const Color(0xFFE64A19),
      },
      {
        'title': 'High-Definition Teleconsultations',
        'subtitle': 'Remote Face-to-Face Care',
        'desc':
            'Encrypted virtual consultation rooms enabling seamless, private video appointments bridging the geographical gap between doctors and patients.',
        'icon': Icons.video_camera_front_rounded,
        'color': const Color(0xFF0288D1),
      },
      {
        'title': 'Smart Medication Management',
        'subtitle': 'Grouped Reminders & Adherence',
        'desc':
            'Intelligent schedules that group concurrent doses, track Take, Skip, or Snooze actions, and keep treatment routines effortless and error-free.',
        'icon': Icons.alarm_on_rounded,
        'color': const Color(0xFF388E3C),
      },
      {
        'title': 'Seamless Pharmacy Routing',
        'subtitle': 'Direct Prescription Routing',
        'desc':
            'Instant digital routing of prescribed medicines to verified local pharmacies for prompt dispensing, transparent billing, and accurate inventory verification.',
        'icon': Icons.local_pharmacy_rounded,
        'color': const Color(0xFFC2185B),
      },
      {
        'title': 'Comprehensive Diagnostic Coordination',
        'subtitle': 'End-to-End Lab Booking',
        'desc':
            'Streamlined booking for home sample collections or center visits, with verified diagnostic test results delivered directly into your personal Health Vault.',
        'icon': Icons.science_rounded,
        'color': const Color(0xFFF57C00),
      },
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionHeader(
                title: 'Core Capabilities',
                subtitle:
                    'An abstract overview of how MedEcos harmonizes everyday healthcare experiences without technical complexity.',
              ),
              const SizedBox(height: 28),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          for (int i = 0; i < features.length; i += 2) ...[
                            _buildFeatureCard(
                              title: features[i]['title'] as String,
                              subtitle: features[i]['subtitle'] as String,
                              description: features[i]['desc'] as String,
                              icon: features[i]['icon'] as IconData,
                              color: features[i]['color'] as Color,
                            ),
                            const SizedBox(height: 20),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        children: [
                          for (int i = 1; i < features.length; i += 2) ...[
                            _buildFeatureCard(
                              title: features[i]['title'] as String,
                              subtitle: features[i]['subtitle'] as String,
                              description: features[i]['desc'] as String,
                              icon: features[i]['icon'] as IconData,
                              color: features[i]['color'] as Color,
                            ),
                            const SizedBox(height: 20),
                          ],
                        ],
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    for (final f in features) ...[
                      _buildFeatureCard(
                        title: f['title'] as String,
                        subtitle: f['subtitle'] as String,
                        description: f['desc'] as String,
                        icon: f['icon'] as IconData,
                        color: f['color'] as Color,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return _ExpandableFeatureCard(
      title: title,
      subtitle: subtitle,
      description: description,
      icon: icon,
      color: color,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 3. TERMS & POLICIES SECTION
  // ─────────────────────────────────────────────────────────────
  Widget _buildTermsAndPoliciesSection(bool isWide) {
    final policies = [
      {
        'icon': Icons.lock_person_rounded,
        'title': 'Patient Data Sovereignty & Ownership',
        'color': const Color(0xFF00796B),
        'content':
            'At MedEcos, we fundamentally believe that your personal health history belongs solely to you. You maintain absolute ownership of every prescription, lab report, and medical document stored within your Health Vault. We never monetize, trade, or expose your private health data to third parties without your explicit command.',
      },
      {
        'icon': Icons.handshake_rounded,
        'title': 'Consent-Governed Interprofessional Access',
        'color': const Color(0xFF1565C0),
        'content':
            'Medical collaboration is built on trust. Healthcare practitioners—including Doctors, Pharmacists, and Diagnostic Pathologists—can only review relevant sections of your health profile when you grant explicit, granular consent. Furthermore, you retain the right to revoke access to any document or provider instantly at any time.',
      },
      {
        'icon': Icons.security_rounded,
        'title': 'End-to-End Encryption & Security Standards',
        'color': const Color(0xFF6A1B9A),
        'content':
            'To protect sensitive health information, MedEcos enforces rigorous encryption standards. Data transmitted across our network is safeguarded against unauthorized interception, ensuring confidentiality during teleconsultations, prescription routing, and diagnostic delivery.',
      },
      {
        'icon': Icons.gavel_rounded,
        'title': 'Medical Disclaimer & AI Scope of Practice',
        'color': const Color(0xFFD32F2F),
        'content':
            'MedEcos provides advanced digital healthcare enablement tools, record organization, and AI-assisted wellness insights. While our AI companion (Vaidya) offers educational explanations, it is not a substitute for professional clinical judgment. Critical medical diagnoses, treatment adjustments, and emergency care must always be directed by qualified, licensed physicians.',
      },
      {
        'icon': Icons.fact_check_rounded,
        'title': 'Professional Credentialing & Ethical Conduct',
        'color': const Color(0xFFE65100),
        'content':
            'We are committed to maintaining a verified, trustworthy ecosystem. All participating medical doctors, dispensing pharmacists, and diagnostic laboratories undergo thorough credential checks to uphold the highest standards of professional ethics, accuracy, and patient safety.',
      },
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionHeader(
                title: 'Our Terms & Privacy Pillars',
                subtitle:
                    'Transparent commitments governing data protection, ethical medical collaboration, and patient privacy.',
              ),
              const SizedBox(height: 28),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          for (int i = 0; i < policies.length; i += 2) ...[
                            _ExpandablePolicyCard(
                              title: policies[i]['title'] as String,
                              content: policies[i]['content'] as String,
                              icon: policies[i]['icon'] as IconData,
                              color: policies[i]['color'] as Color,
                            ),
                            const SizedBox(height: 20),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        children: [
                          for (int i = 1; i < policies.length; i += 2) ...[
                            _ExpandablePolicyCard(
                              title: policies[i]['title'] as String,
                              content: policies[i]['content'] as String,
                              icon: policies[i]['icon'] as IconData,
                              color: policies[i]['color'] as Color,
                            ),
                            const SizedBox(height: 20),
                          ],
                        ],
                      ),
                    ),
                  ],
                )
              else
                ...policies.map((p) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: _ExpandablePolicyCard(
                      title: p['title'] as String,
                      content: p['content'] as String,
                      icon: p['icon'] as IconData,
                      color: p['color'] as Color,
                    ),
                  );
                }),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 4. ECOSYSTEM ROLES SECTION
  // ─────────────────────────────────────────────────────────────
  Widget _buildEcosystemRolesSection(bool isWide) {
    final roles = [
      {
        'role': 'Patient',
        'tag': 'The Heart of Care',
        'color': AppColors.patientPrimary,
        'lightColor': AppColors.patientLight,
        'icon': Icons.favorite_rounded,
        'desc':
            'Patients gain effortless command over their entire health journey—from instant prescription scans and organized reminders to secure teleconsultations and complete record portability.',
      },
      {
        'role': 'Doctor',
        'tag': 'Clinical Excellence & Clarity',
        'color': AppColors.doctorPrimary,
        'lightColor': AppColors.doctorLight,
        'icon': Icons.medical_services_rounded,
        'desc':
            'Physicians access comprehensive, verified patient histories with explicit consent, enabling precise diagnoses, seamless e-prescriptions, and remote teleconsultations without administrative burdens.',
      },
      {
        'role': 'Pharmacist',
        'tag': 'Precision Dispensing & Trust',
        'color': AppColors.pharmaPrimary,
        'lightColor': AppColors.pharmaLight,
        'icon': Icons.local_pharmacy_rounded,
        'desc':
            'Pharmacists receive clear, verified digital prescriptions, manage inventory tracking effortlessly, and ensure patients receive accurate medication guidance and transparent billing.',
      },
      {
        'role': 'Pathologist & Lab',
        'tag': 'Diagnostic Accuracy & Speed',
        'color': AppColors.pathoPrimary,
        'lightColor': AppColors.pathoLight,
        'icon': Icons.biotech_rounded,
        'desc':
            'Diagnostic laboratories coordinate home sample collections and test processing smoothly, transmitting verified digital reports directly into the patient’s Health Vault without delay.',
      },
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionHeader(
                title: 'The Multi-Role Healthcare Continuum',
                subtitle:
                    'How MedEcos connects all four pillars of healthcare into a synchronized, collaborative network.',
              ),
              const SizedBox(height: 28),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          for (int i = 0; i < roles.length; i += 2) ...[
                            _ExpandableRoleCard(
                              role: roles[i]['role'] as String,
                              tag: roles[i]['tag'] as String,
                              desc: roles[i]['desc'] as String,
                              icon: roles[i]['icon'] as IconData,
                              color: roles[i]['color'] as Color,
                              lightColor: roles[i]['lightColor'] as Color,
                            ),
                            const SizedBox(height: 20),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        children: [
                          for (int i = 1; i < roles.length; i += 2) ...[
                            _ExpandableRoleCard(
                              role: roles[i]['role'] as String,
                              tag: roles[i]['tag'] as String,
                              desc: roles[i]['desc'] as String,
                              icon: roles[i]['icon'] as IconData,
                              color: roles[i]['color'] as Color,
                              lightColor: roles[i]['lightColor'] as Color,
                            ),
                            const SizedBox(height: 20),
                          ],
                        ],
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    for (final r in roles) ...[
                      _ExpandableRoleCard(
                        role: r['role'] as String,
                        tag: r['tag'] as String,
                        desc: r['desc'] as String,
                        icon: r['icon'] as IconData,
                        color: r['color'] as Color,
                        lightColor: r['lightColor'] as Color,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STATEFUL EXPANDABLE CARD COMPONENTS
// ─────────────────────────────────────────────────────────────

class _ExpandableFeatureCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;

  const _ExpandableFeatureCard({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
  });

  @override
  State<_ExpandableFeatureCard> createState() => _ExpandableFeatureCardState();
}

class _ExpandableFeatureCardState extends State<_ExpandableFeatureCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: widget.color.withOpacity(_isExpanded ? 0.6 : 0.15), width: 1.2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(widget.icon, color: widget.color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.subtitle.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: widget.color,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.description,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                    maxLines: _isExpanded ? null : 2,
                    overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _isExpanded ? "▲  Show Less" : "▼  Read More",
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: widget.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpandableRoleCard extends StatefulWidget {
  final String role;
  final String tag;
  final String desc;
  final IconData icon;
  final Color color;
  final Color lightColor;

  const _ExpandableRoleCard({
    required this.role,
    required this.tag,
    required this.desc,
    required this.icon,
    required this.color,
    required this.lightColor,
  });

  @override
  State<_ExpandableRoleCard> createState() => _ExpandableRoleCardState();
}

class _ExpandableRoleCardState extends State<_ExpandableRoleCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: widget.color.withOpacity(_isExpanded ? 0.6 : 0.25), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.lightColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(widget.icon, color: widget.color, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.role,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: widget.color,
                        ),
                      ),
                      Text(
                        widget.tag,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.desc,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
              maxLines: _isExpanded ? null : 2,
              overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Text(
              _isExpanded ? "▲  Show Less" : "▼  Read More",
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: widget.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpandablePolicyCard extends StatefulWidget {
  final String title;
  final String content;
  final IconData icon;
  final Color color;

  const _ExpandablePolicyCard({
    required this.title,
    required this.content,
    required this.icon,
    required this.color,
  });

  @override
  State<_ExpandablePolicyCard> createState() => _ExpandablePolicyCardState();
}

class _ExpandablePolicyCardState extends State<_ExpandablePolicyCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: widget.color.withOpacity(_isExpanded ? 0.6 : 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: widget.color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.content,
              style: const TextStyle(
                fontSize: 14.5,
                color: AppColors.textPrimary,
                height: 1.6,
              ),
              maxLines: _isExpanded ? null : 3,
              overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Text(
              _isExpanded ? "▲  Show Less" : "▼  Read More",
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: widget.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpandableVisionCard extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String badgeText;
  final Color badgeColor;
  final String title;
  final String description;
  final List<String> highlights;

  const _ExpandableVisionCard({
    required this.icon,
    required this.iconColor,
    required this.badgeText,
    required this.badgeColor,
    required this.title,
    required this.description,
    required this.highlights,
  });

  @override
  State<_ExpandableVisionCard> createState() => _ExpandableVisionCardState();
}

class _ExpandableVisionCardState extends State<_ExpandableVisionCard> {
  bool _isExpanded = true; // Goal and aim default to fully open!

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: widget.iconColor.withOpacity(_isExpanded ? 0.5 : 0.15), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: widget.iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(widget.icon, color: widget.iconColor, size: 30),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: widget.badgeColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.badgeText,
                    style: TextStyle(
                      color: widget.iconColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.description,
              style: const TextStyle(
                fontSize: 14.5,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
              maxLines: _isExpanded ? null : 3,
              overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
            if (_isExpanded) ...[
              const SizedBox(height: 22),
              const Divider(height: 1),
              const SizedBox(height: 18),
              ...widget.highlights.map(
                (point) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        color: widget.iconColor,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          point,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            Text(
              _isExpanded ? "▲  Show Less" : "▼  Read More",
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: widget.iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
