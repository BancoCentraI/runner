import 'package:akillisletme/feature/home/material_widgets/material_widgets_view.dart';
import 'package:flutter/material.dart';

abstract class MaterialWidgetsViewMode extends State<MaterialWidgetsView> {
  late final ScrollController scrollController;
  late final TextEditingController textController;

  bool switchValue = false;
  bool checkboxValue = false;
  int radioValue = 0;
  double sliderValue = 0.5;
  Set<int> selectedFilters = {0};
  int choiceIndex = 0;
  Set<String> segmentSelection = {'day'};

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
    textController = TextEditingController();
  }

  @override
  void dispose() {
    scrollController.dispose();
    textController.dispose();
    super.dispose();
  }
}
