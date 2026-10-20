<?php
require_once __DIR__ . '/../helpers/response.php';
require_once __DIR__ . '/../models/Branch.php';

$branchModel = new Branch();
$branches = $branchModel->getAll();

jsonResponse('success', $branches);
