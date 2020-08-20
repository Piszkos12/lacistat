<?php
include_once "guid.php";

header("Cache-Control: no-store, no-cache, must-revalidate, max-age=0");
header("Cache-Control: post-check=0, pre-check=0", false);
header("Pragma: no-cache");

ini_set("log_errors", 1);
ini_set("error_log", "php.log");

error_log(json_encode($_POST));

if ($_POST["event"] == "initSession") {
    $files = glob("events/*");
    foreach ($files as $file) {
        if (is_file($file)) {
            unlink($file);
        }
    }
    $files = glob("stats/*");
    foreach ($files as $file) {
        if (is_file($file)) {
            unlink($file);
        }
    }
    file_put_contents("state.txt", "initial");
    die;
}

if ($_POST["event"] == "setMap") {
    file_put_contents("state.txt", "game");
    file_put_contents("map.txt", $_POST["map"]);
    die;
}

if ($_POST["event"] == "endMap") {
    file_put_contents("state.txt", "stat");
    die;
}

if ($_POST["event"] == "fireStatUpdate") {
    file_put_contents("stats/" . $_POST["name"], json_encode($_POST));
}

file_put_contents("events/" . getGUID(), json_encode($_POST));
