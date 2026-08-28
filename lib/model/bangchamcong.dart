class BangChamCongCaNhan {
  final bool status;
  final int thang;
  final int nam;
  final List<KhuVuc> khuvucs;

  BangChamCongCaNhan({
    required this.status,
    required this.thang,
    required this.nam,
    required this.khuvucs,
  });

  factory BangChamCongCaNhan.fromJson(Map<String, dynamic> json) {
    return BangChamCongCaNhan(
      status: json['status'] ?? false,
      thang: json['thang'] ?? 0,
      nam: json['nam'] ?? 0,
      khuvucs: (json['khuvucs'] as List<dynamic>?)
          ?.map((e) => KhuVuc.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }
}

class KhuVuc {
  final int id;
  final String ten;
  final int iskhongchamve;
  final List<NhanVien> nhanvien;

  KhuVuc({
    required this.id,
    required this.ten,
    required this.iskhongchamve,
    required this.nhanvien,
  });

  factory KhuVuc.fromJson(Map<String, dynamic> json) {
    return KhuVuc(
      id: json['id'] ?? 0,
      ten: json['ten'] ?? '',
      iskhongchamve: json['iskhongchamve'] ?? 0,
      nhanvien: (json['nhanvien'] as List<dynamic>?)
          ?.map((e) => NhanVien.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }
}

class NhanVien {
  final int id;
  final String hoten;
  final Map<String, double> ngay; // key: ngày (1-31), value: số giờ
  final double tong;

  NhanVien({
    required this.id,
    required this.hoten,
    required this.ngay,
    required this.tong,
  });

  factory NhanVien.fromJson(Map<String, dynamic> json) {
    final ngayMap = json['ngay'] as Map<String, dynamic>? ?? {};
    final convertedNgay = <String, double>{};

    ngayMap.forEach((key, value) {
      convertedNgay[key] = (value as num).toDouble();
    });

    return NhanVien(
      id: json['id'] ?? 0,
      hoten: json['hoten'] ?? '',
      ngay: convertedNgay,
      tong: (json['tong'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Tính số ngày đi muộn (ngày có giá trị < 1 nhưng > 0, hoặc thống kê dựa trên quy tắc)
  /// Có thể cần điều chỉnh logic theo yêu cầu backend
  int getLateDays() {
    int lateDays = 0;
    ngay.forEach((day, value) {
      if (value > 0 && value < 1) {
        lateDays++;
      }
    });
    return lateDays;
  }

  /// Tính số ngày đúng giờ (ngày có giá trị >= 1)
  int getOnTimeDays() {
    int onTimeDays = 0;
    ngay.forEach((day, value) {
      if (value >= 1) {
        onTimeDays++;
      }
    });
    return onTimeDays;
  }

  /// Tính số ngày không chấm công (ngày có giá trị = 0)
  int getAbsentDays() {
    int absentDays = 0;
    ngay.forEach((day, value) {
      if (value == 0) {
        absentDays++;
      }
    });
    return absentDays;
  }

  /// Tính số ngày công thực tế (tổng giờ / 8 giờ/ngày)
  double getWorkingDays() {
    return tong / 8;
  }
}
