#!/bin/bash
lit -vv --vg --vg-leak --vg-arg="--trace-children-skip-by-arg=compile,FileCheck" .
