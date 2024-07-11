class UnbordingContent {
  String image;
  String title;
  String discription;

  UnbordingContent(
      {required this.image, required this.title, required this.discription});
}

List<UnbordingContent> contents = [
  UnbordingContent(
      title: 'Welcome to FirstBus',
      image: 'assets/onboarding_1.png',
      discription: "The smart solution for managing school transportation."),
  UnbordingContent(
    title: 'Real-time Tracking',
    image: 'assets/onboarding_2.png',
    discription: "Track your bus in real-time.",
  ),
];
