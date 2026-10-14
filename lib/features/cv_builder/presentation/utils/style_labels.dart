import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_style.dart';

String styleName(CvStyle style) => switch (style) {
  CvStyle.international => AppStrings.styleInternational,
  CvStyle.gulf => AppStrings.styleGulf,
  CvStyle.southAsia => AppStrings.styleSouthAsia,
};

String styleBody(CvStyle style) => switch (style) {
  CvStyle.international => AppStrings.styleInternationalBody,
  CvStyle.gulf => AppStrings.styleGulfBody,
  CvStyle.southAsia => AppStrings.styleSouthAsiaBody,
};

/// Short name for buttons and pills ("Use Gulf style").
String styleShortName(CvStyle style) => switch (style) {
  CvStyle.international => AppStrings.styleShortInternational,
  CvStyle.gulf => AppStrings.styleShortGulf,
  CvStyle.southAsia => AppStrings.styleShortSouthAsia,
};
