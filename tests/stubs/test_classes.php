<?php

namespace testModel;

class baseClass {
    public function __construct(testClass $obj)
    {

    }
}

class staticClass {
    public static function someStaticMethod()
    {

    }
}

class anotherClass {
    public static $_param = 1;
}
