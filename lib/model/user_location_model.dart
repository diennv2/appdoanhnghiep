class UserLocationModel {
  final String address;
  final double latitude;
  final double longitude;

  UserLocationModel({
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  static final List<UserLocationModel> locationList = [
    UserLocationModel(
      address: 'Sylhet, Bangladesh',
      latitude: 24.909878,
      longitude: 91.861259,
    ),
    UserLocationModel(
      address: 'Western Communication,51 Mitali Unit B,5th Floor Raynagor,Rajbar,Syl,BD',
      latitude: 24.9051854,
      longitude: 91.8872579,
    ),
    UserLocationModel(
      address: 'Leading University,Sylhet',
      latitude: 24.8693875,
      longitude: 91.8049219,
    ),
    UserLocationModel(
      address: '1, Grosvenor House, Durkins Rd, East Grinstead RH19 2RW, UK',
      latitude: 51.128503,
      longitude: -0.008932,
    ),
    UserLocationModel(
      address: '198 Haslett Ave E, Three Bridges, Crawley RH10 1LY, UK',
      latitude: 51.113867,
      longitude: -0.174212,
    ),
    UserLocationModel(
      address: 'Unit B1, Smallmead House, Horley RH6 9LW, UK',
      latitude: 51.171569,
      longitude: -0.164825,
    ),
    UserLocationModel(
      address: 'Office 3, The Courtyard, 30 Worthing Rd, Horsham RH12 1SL, UK',
      latitude: 51.062189,
      longitude: -0.327829,
    ),
    UserLocationModel(
      address: '143 South Rd, Haywards Heath RH16 4LY, UK',
      latitude: 51.002834,
      longitude: -0.100827,
    ),
  ];
}
