export SIGNATURE=/data01/temp/mirror/ocp414-416/result/release-signatures/
export REPO=service

sh signature.tmpl
sh cv-upstream.tmpl
sh clusters-binding.tmpl
sh clusters-placement.tmpl
