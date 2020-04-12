#!/bin/bash
. ./00_env_pipeline.sh  > ./result_check.txt
is_needed_to_build >> ./result_check.txt

echo $NEED_TO_BUILD