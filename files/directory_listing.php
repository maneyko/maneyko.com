<!DOCTYPE html>
<html>
  <head>
<?php
function set_if_blank(&$var, $value) {
  if (!isset($var)) {
    $var = $value;
  }
}

set_if_blank($PAGE_HEADING,  'Directory Contents');
set_if_blank($PAGE_TITLE,    'My Webpage!');
set_if_blank($FILE_SORT_KEY, 'mtime');
set_if_blank($SKIP_PATTERN,  '/^$/');
?>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta charset="utf-8">
    <link rel="shortcut icon" href="/favicon.ico" type="image/x-icon">
<?php
if (is_file("{$_SERVER['DOCUMENT_ROOT']}/favicon.ico"))
  echo <<< EOT
    <link rel="icon" href="/favicon.ico" type="image/x-icon">

EOT;
?>
    <link rel="stylesheet" type="text/css" href="https://fonts.googleapis.com/css?family=Work+Sans:100,400,700&display=swap">
    <link rel="stylesheet" type="text/css" href="https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/4.6.0/css/bootstrap.min.css"/>
    <link rel="stylesheet" type="text/css" href="https://cdn.datatables.net/v/bs4-4.6.0/jq-3.6.0/dt-1.11.3/datatables.min.css"/>

    <title><?php echo $PAGE_TITLE; ?></title>
    <style>

      table.dataTable thead .sorting:after,
      table.dataTable thead .sorting:before,
      table.dataTable thead .sorting_asc:after,
      table.dataTable thead .sorting_asc:before,
      table.dataTable thead .sorting_asc_disabled:after,
      table.dataTable thead .sorting_asc_disabled:before,
      table.dataTable thead .sorting_desc:after,
      table.dataTable thead .sorting_desc:before,
      table.dataTable thead .sorting_desc_disabled:after,
      table.dataTable thead .sorting_desc_disabled:before {
        display: none;
      }

      body {
        margin: 0 auto;
        margin-left: 15px;
        margin-right: 15px;
        font-family: 'Work Sans', sans-serif;
      }
      h1 {
        text-align: center;
        font-family: 'Work Sans', sans-serif;
        font-size: 300%;
        font-weight: lighter;
      }

      table.dataTable thead,
      table.dataTable th,
      table.dataTable td {
        vertical-align: middle;
        word-break: break-all;
      }

    </style>
  </head>
  <body>
    <br />
    <br />
    <div class="row">
      <div class="col-1 col-sm-1 col-md-2 col-lg-2 col-xl-2"></div>
      <div class="col-10 col-sm-10 col-md-8 col-lg-8 col-xl-8">
        <h1 class="text-center">
          <span class="name-text"><?php echo $PAGE_HEADING; ?></span>
        </h1>
      </div>
      <div class="col-1 col-sm-1 col-md-2 col-lg-2 col-xl-2"></div>
    </div>  <!-- .row -->

    <br />

    <div class="row">
      <div class="col-lg-1 col-xl-1"></div>
      <div class="col-12 col-sm-12 col-md-12 col-lg-10 col-xl-10">
        <p class="text-center">
          <table id="dtBasicExample" class="table" style="width:100%">
            <thead>
              <tr>
<?php
$headers = array('#', 'Filename', 'Size', 'Last Modified');
foreach($headers as $h) {
    echo <<< EOT
                <th scope="col">$h</th>

EOT;
}
?>
              </tr>
            </thead>
            <tbody>
              <tr>
                <th scope="row">1</th>
                <td><a href="../">../</td>
                <td data-order=""></td>
                <td data-order=""></td>
              </tr>
<?php
function human_filesize($bytes, $decimals = 2) {
    $bytes_i = intval($bytes);
    $size    = array('B','kB','MB','GB','TB','PB','EB','ZB','YB');
    $factor  = floor((strlen($bytes_i) - 1) / 3);
    return sprintf("%.{$decimals}f ", $bytes_i / pow(1024, $factor)) . @$size[$factor];
}

$stats = array( );
$files = array( );
$dirs  = array( );
foreach(glob("*") as &$fname) {
  if (preg_match($SKIP_PATTERN, $fname))
    continue;
  $stats[$fname] = stat($fname);
  if (is_dir($fname))
    array_push($dirs, $fname);
  else
    array_push($files, $fname);
}

sort($dirs);
usort($files, function($a, $b) use ($stats, $FILE_SORT_KEY) {
  return -(intval($stats[$a][$FILE_SORT_KEY]) <=> intval($stats[$b][$FILE_SORT_KEY]));
});

$all_files = array_merge($dirs, $files);

$count = 2;
foreach ($all_files as &$filename) {
    $file_stats = $stats[$filename];
    if (is_dir($filename)) {
      $filename .= '/';
      $mod_time = '';
      $mtime    = '';
    } else {
      $mtime = $file_stats['mtime'];
      $mod_time = strftime('%a %b %d %Y %r %Z', $mtime);
    }

    $fsize = human_filesize($file_stats['size']);
    echo <<< EOT
              <tr>
                <th scope="row">$count</th>
                <td><a href="$filename">$filename</a></td>
                <td data-order={$file_stats['size']}>$fsize</td>
                <td data-order={$mtime}>$mod_time</td>
              </tr>

EOT;
    $count++;
}

?>
            </tbody>
          </table>
        </p>
      </div>
      <div class="col-lg-1 col-xl-1"></div>
    </div>  <!-- .row -->
    <!-- The time is <?php echo date("Y-m-d-H:i:s"); ?> -->

    <script type="text/javascript" src="https://cdn.datatables.net/v/bs4-4.6.0/jq-3.6.0/dt-1.11.3/datatables.min.js"></script>
    <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/4.6.0/js/bootstrap.min.js"></script>

    <script>
      $(document).ready(function() {
        $("#dtBasicExample").DataTable({
          "paging": false,
          "info": false,
          "searching": false
        });
        // $("#dtBasicExample").DataTable();
        // $('.dataTables_length').addClass('bs-select');
      });
    </script>
  </body>
</html>
