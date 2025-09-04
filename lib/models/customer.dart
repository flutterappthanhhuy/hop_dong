import 'package:hive/hive.dart';
part 'customer.g.dart';


@HiveType(typeId: 34)
class Customer extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String name;
  @HiveField(2) String taxCode; // MST
  @HiveField(3) String address;
  @HiveField(4) String? representative;
  Customer({
    required this.id,
    required this.name,
    required this.taxCode,
    required this.address,
    this.representative,
  });
}