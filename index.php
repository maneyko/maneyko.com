<?php
require_once __DIR__ . "/vendor/autoload.php";
use Symfony\Component\Dotenv\Dotenv;

$dotenv = new Dotenv();
$env_files = array(".env", ".env.local");

foreach($env_files as &$env_file) {
  if (is_file($env_file))
    $dotenv->load(__DIR__ . "/$env_file");
}
?>
<!DOCTYPE html>
<html>
<?php
include __DIR__ . "/header.php";
?>
  <body>
    <style>
      td {
        border:1px solid #333;
      }
    </style>
    <br />
    <br />
<?php
if (!empty($_GET["name"])) {
  $name = htmlspecialchars($_GET["name"]);
  echo <<< EOT
  <h1>Hello {$name}!</h1>

EOT;
}
?>

    <div class="row">
      <div class="col-12 col-sm-12 col-md-12 col-lg-12 col-xl-12">
        <h1 class="text-center">
          <span class="name-text">Peter Maneykowski</span>
        </h1>
      </div>
    </div>  <!-- .row -->

    <br />

    <div class="row">
      <div class="col-12 col-sm-12 col-md-12 col-lg-12 col-xl-12">
        <p class="text-center">
          <img class="main-pic rounded-circle"
               style="border: 1px solid"
               width=220
               height=220
               src="/static/IMG_1955_sq2.jpg">
        </p>
      </div>
    </div>  <!-- .row -->

    <br />

    <div class="row">

<?php
use Symfony\Component\Yaml\Yaml;

$icons = Yaml::parseFile(__DIR__ . "/static/icons.yml");

foreach($icons as &$icon) {
  $a_tag = "<a";

  foreach($icon["a_attrs"] as $key => $value)
    $a_tag .= " $key=\"$value\"";

  $a_tag .= "><i class=\"fa fa-icon {$icon["i_attrs"]["class"]}\"";
  foreach($icon["i_attrs"] as $key => $value) {
    if ($key == "class") continue;
    $a_tag .= " $key=\"$value\"";
  }
  $a_tag .= "></i></a>";

  echo <<< EOT
      <div class="col-4 col-sm-4 col-md-2 col-lg-2 col-xl-2">
        <p class="text-center">
          {$icon["name"]}
          <br />
          $a_tag
        </p>
      </div>  <!-- .col-4 -->

EOT;
}
?>
    </div>  <!-- .row -->

    <!-- The time is <?php echo date("Y-m-d-H:i:s"); ?> -->
    <!-- Current PHP version: <?php echo phpversion(); ?> -->

    <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.1.0/jquery.min.js"></script>


<?php
$scripts = array(
  // "https://code.jquery.com/jquery-3.3.1.slim.min.js"                          => "sha384-q8i/X+965DzO0rT7abK41JStQIAqVgRVzpbzo5smXKp4YfRvH+8abtTE1Pi6jizo",
  "https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.14.7/umd/popper.min.js" => "sha384-UO2eT0CpHqdSJQ6hJty5KVphtPhzWj9WO1clHTMGa3JDZwrnQq4sF86dIHNDz0W1",
  "https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/js/bootstrap.min.js"    => "sha384-JjSmVgyd0p3pXB1rRibZUAYoIIy6OrQ6VrjIEaFf/nJGzIxFDsf4x0xIM+B07jRM"
);

foreach($scripts as $src => $integrity ) {
  echo <<< EOT
    <script src="$src" integrity="$integrity" crossorigin="anonymous"></script>

EOT;
}
?>

    <script>
      $(function () {
        $("[data-toggle='tooltip']").tooltip();
      });

      $('.name-text').click(function() {
        $('.main-pic').toggle();
      });

      $('.main-pic').click(function() {
        $(this).hide();
      });
    </script>
  </body>
</html>
