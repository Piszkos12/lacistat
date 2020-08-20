<?php
include_once "guid.php";

header("Cache-Control: no-store, no-cache, must-revalidate, max-age=0");
header("Cache-Control: post-check=0, pre-check=0", false);
header("Pragma: no-cache");

ini_set("log_errors", 1);
ini_set("error_log", "php.log");

if ($_SERVER['REQUEST_METHOD'] == "POST") {
    if ($_POST["event"] == "getState") {
        echo file_get_contents("state.txt");
        die;
    }
    if ($_POST["event"] == "getEvents") {
        $events = [];
        $files = glob("events/*");
        usort($files, function ($a, $b) {
            return filemtime($a) > filemtime($b);
        });
        foreach ($files as $file) {
            if (is_file($file)) {
                $event = json_decode(file_get_contents($file));
                $events[] = $event;
                unlink($file);
            }
        }
        echo json_encode($events);
        die;
    }
    die;
}

$status = file_get_contents("state.txt");

if ($status == "game") {
    $map = file_get_contents("map.txt");
    $html = file_get_contents("html/" . $status . ".html");
    $html = str_replace("[MAP]", $map, $html);
    echo $html;
    die;
}

if ($status == "initial") {
    $html = file_get_contents("html/" . $status . ".html");
    echo $html;
    die;
}

if ($status == "stat") {
    $html = file_get_contents("html/" . $status . ".html");
    $files = glob("stats/*");
    $stat = "";
    foreach ($files as $file) {
        if (is_file($file)) {
            $thisStat = json_decode(file_get_contents($file),true);
            $stat.=$thisStat["name"]." bullets:".$thisStat["fireCnt"]." melees:".$thisStat["meleeCnt"]."<br/>";
        }
    }
    $html = str_replace("[STAT]", $stat, $html);
    echo $html;
    die;
}