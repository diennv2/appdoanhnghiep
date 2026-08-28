class ApiConfig {
  static const String BASE_URL = 'https://chamcongdoanhnghiep.techber.vn';

  // ── Authenticator endpoints ──────────────────────────────────────────────
  static const String LOGIN          = '/api-login';
  static const String REFRESH_TOKEN  = '/refresh-token';
  // NOTE: LOGOUT uses DELETE method on the same refresh-token path
  static const String LOGOUT         = '/refresh-token';
  static const String GET_PERMISSION = '/get-permissions';
  static const String SIGNUP = '/signup';
  static const String DELETE_BY_USERID = '/deletebyuserid';
  // ── AppServices endpoints ────────────────────────────────────────────────
  static const String HEALTH_CHECK          = '/api/healthcheck';
  static const String GET_USER_INFO         = '/api/getuserinfo';
  static const String GET_ATTENDANCES       = '/api/getattendances';
  static const String GET_OWNED_ATTENDANCES = '/api/getownedattendances';
  static const String BAO_CAO_TONG          = '/api/baocaotong';
  static const String BANG_CHAM_CONG        = '/api/bangchamcong';
  static const String BANG_CHAM_CONG_CA_NHAN= '/api/bangchamcongcanhan';
  static const String LICH_SU_DIEM_DANH     = '/api/getallattendances';

  // ── Kept for backward-compat (check-in/out, location, notification) ───────
  // These endpoints are not yet available in the new API documentation.
  // TODO: Update when backend provides these endpoints.
  static const String ATTENDANCE_CHECK_IN    = '/attendance/check-in';
  static const String ATTENDANCE_CHECK_OUT   = '/attendance/check-out';
  static const String ATTENDANCE_BREAK_COUNT = '/attendance/break-count';
  static const String ATTENDANCE_INSERT      = '/attendance/insert';
  static const String LOCATION_TRACK        = '/location/track';
  static const String LOCATION_HISTORY      = '/location/history';
  static const String NOTIFICATION_LIST     = '/notification/list';
  static const String NOTIFICATION_READ     = '/notification/read';
  static const String NOTIFICATION_DELETE   = '/notification/delete';
  static const String RESET_PASSWORD        = '/auth/reset-password';
  static const String UPLOAD_PROFILE_PHOTO  = '/api/uploadphoto';
}