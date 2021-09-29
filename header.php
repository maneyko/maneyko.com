  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta charset="utf-8">
    <meta name="google" content="notranslate">
    <meta http-equiv="Content-Language" content="en">
    <link rel="shortcut icon" href="/favicon.ico" type="image/x-icon">
<?php
function set_if_blank(&$var, $value) {
  if (!isset($var)) {
    $var = $value;
  }
}

set_if_blank($PAGE_TITLE, "Peter's Webpage!");

$sheets = array(
  "https://fonts.googleapis.com/css?family=Work+Sans:100&display=swap",
  "https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/css/bootstrap.min.css",
  "https://fonts.googleapis.com/css2?family=Work+Sans&display=swap",
  "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css",
  "/static/css/main.css"
);
foreach ($sheets as &$sheet) {
  echo <<< EOT
    <link rel="stylesheet" href="$sheet">

EOT;
}
?>
    <title><?php echo $PAGE_TITLE; ?></title>
  </head>
