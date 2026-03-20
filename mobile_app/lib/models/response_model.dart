class Res<T> {
  final bool ok;
  final T? data;
  final String? message, error;
  const Res({required this.ok, this.data, this.message, this.error});
  factory Res.success(T data, [String? msg]) =>
      Res(ok: true, data: data, message: msg);
  factory Res.fail(String err) => Res(ok: false, error: err);
}
