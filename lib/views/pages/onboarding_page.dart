import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:trackedify/views/pages/get_started_page.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final pages = [
      OnboardingPageModel(
        title: 'Welcome to Trackedify',
        description: 'Manage your expenses efficiently and smartly',
        lottieAsset: 'assets/lotties/wallet2.json',
        bgColor: const Color(0xFF287ce9),
      ),
      OnboardingPageModel(
        title: 'Track Your Expenses',
        description:
            'Add & categorize your daily expenses easily and delete them when you need to',
        lottieAsset: 'assets/lotties/list.json',
        bgColor: const Color(0xfffeae4f),
      ),
      OnboardingPageModel(
        title: 'Analyze & Grow',
        description: 'Get insights with charts and statistics',
        lottieAsset: 'assets/lotties/chart.json',
      ),
    ];

    return OnboardingPagePresenter(
      pages: pages,
      // Default actions: skip & finish go to GetStartedPage (replace)
      onSkip: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const GetStartedPage()),
        );
      },
      onFinish: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const GetStartedPage()),
        );
      },
    );
  }
}

class OnboardingPagePresenter extends StatefulWidget {
  final List<OnboardingPageModel> pages;
  final VoidCallback? onSkip;
  final VoidCallback? onFinish;

  const OnboardingPagePresenter({
    super.key,
    required this.pages,
    this.onSkip,
    this.onFinish,
  });

  @override
  State<OnboardingPagePresenter> createState() =>
      _OnboardingPagePresenterState();
}

class _OnboardingPagePresenterState extends State<OnboardingPagePresenter> {
  int _currentPage = 0;
  final PageController _pageController = PageController(initialPage: 0);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_currentPage == widget.pages.length - 1) {
      widget.onFinish?.call();
    } else {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = widget.pages[_currentPage];
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        color: model.bgColor,
        child: SafeArea(
          child: Column(
            children: [
              // PageView takes available space
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: widget.pages.length,
                  onPageChanged: (idx) {
                    setState(() {
                      _currentPage = idx;
                    });
                  },
                  itemBuilder: (context, idx) {
                    final item = widget.pages[idx];
                    return Center(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Lottie.asset(
                                item.lottieAsset,
                                fit: BoxFit.contain,
                                height:
                                    MediaQuery.of(context).size.height * 0.45,
                                repeat: true,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                item.title,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: item.textColor,
                                      fontSize: 22,
                                    ),
                              ),
                            ),
                            Container(
                              constraints: const BoxConstraints(maxWidth: 320),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24.0,
                                vertical: 8.0,
                              ),
                              child: Text(
                                item.description,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: item.textColor,
                                      fontSize: 15,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Page indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: widget.pages
                    .map(
                      (item) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: _currentPage == widget.pages.indexOf(item)
                            ? 30
                            : 8,
                        height: 8,
                        margin: const EdgeInsets.all(4.0),
                        decoration: BoxDecoration(
                          color: item.indicatorColor,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    )
                    .toList(),
              ),

              // Bottom bar with Skip and Next/Finish
              SizedBox(
                height: 100,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.comfortable,
                          foregroundColor: model.textColor,
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () {
                          widget.onSkip?.call();
                        },
                        child: const Text("Skip"),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.comfortable,
                          foregroundColor: model.textColor,
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: _goNext,
                        child: Row(
                          children: [
                            Text(
                              _currentPage == widget.pages.length - 1
                                  ? "Finish"
                                  : "Next",
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _currentPage == widget.pages.length - 1
                                  ? Icons.done
                                  : Icons.arrow_forward,
                              color: model.textColor,
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
      ),
    );
  }
}

class OnboardingPageModel {
  final String title;
  final String description;
  final String lottieAsset;
  final Color bgColor;
  final Color textColor;
  final Color indicatorColor;

  OnboardingPageModel({
    required this.title,
    required this.description,
    required this.lottieAsset,
    this.bgColor = Colors.blue,
    this.textColor = Colors.white,
    Color? indicatorColor,
  }) : indicatorColor = indicatorColor ?? (textColor);
}
