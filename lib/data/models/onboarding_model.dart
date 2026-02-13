import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Onboarding slide data model
class OnboardingSlide {
  final String title;
  final String description;
  final String? lottieUrl;
  final String? imageUrl;
  final Color? backgroundColor;

  const OnboardingSlide({
    required this.title,
    required this.description,
    this.lottieUrl,
    this.imageUrl,
    this.backgroundColor,
  });

  /// Check if slide has animation
  bool get hasAnimation => lottieUrl != null && lottieUrl!.isNotEmpty;

  /// Check if slide has image
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
}

/// Onboarding slides data
final List<OnboardingSlide> onboardingSlides = [
  OnboardingSlide(
    title: "Enjoy fast, reliable delivery\nstraight to your doorstep",
    description:
        "Online reservation and home delivery system for restaurants and cafes.",
    imageUrl:
        "https://cdn.dribbble.com/users/4613/screenshots/15444654/media/565d70659639556272551523b1262d05.png?compress=1&resize=800x600",
    backgroundColor: AppColors.surface,
  ),
  OnboardingSlide(
    title: "Discover new tastes\naround you",
    description:
        "Browse hundreds of cuisines.\nFrom burgers to sushi, find it all.",
    imageUrl:
        "https://cdn.dribbble.com/users/1615584/screenshots/15710288/media/7864293f2f81665a882ce99c64b5e679.jpg?compress=1&resize=800x600",
    backgroundColor: AppColors.surface,
  ),
  OnboardingSlide(
    title: "Easy payment &\nfast delivery",
    description:
        "Pay securely with any method and\ntrack your order in real-time.",
    imageUrl:
        "https://cdn.dribbble.com/users/285475/screenshots/6007204/delivery_drib_4x.png?compress=1&resize=800x600",
    backgroundColor: AppColors.surface,
  ),
];

/// Total number of slides
int get onboardingSlideCount => onboardingSlides.length;

/// Check if on last slide
bool isLastSlide(int currentPage) => currentPage == onboardingSlides.length - 1;
