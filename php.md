```
private function log($data) {
  $message = print_r($data, true);
  if (is_string($data)) {
    $message = $data;
  } elseif (is_numeric($data)) {
    $message = strval($data);
  } elseif (is_bool($data)) {
    $message = $data?'true':'false';
  }

  $handle = fopen('/var/log/zzz_ae.log', 'a');
  fwrite($handle, date('c').': '.$message.PHP_EOL);
  fclose($handle);
}
```
