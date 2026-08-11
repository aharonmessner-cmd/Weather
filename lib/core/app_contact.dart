/// Identity used in outbound `User-Agent` headers for every third-party
/// service this app calls (NWS, Nominatim, ...). Both ask for a descriptive
/// User-Agent with a way to reach the developer, for the same reason: so
/// they can contact us instead of silently blocking the app if something
/// about our usage looks abusive.
///
/// One place to update if this app ever changes hands.
class AppContact {
  const AppContact._();

  static const String appName = 'PersonalWeatherApp';
  static const String contactEmail = 'chatty870@gmail.com';
}
