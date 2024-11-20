export SIGNATURE=/data01/temp/mirror/ocp414-416/result/release-signatures/
export REPO=ocp414-416

sh signature.tmpl
sh cv-upstream.tmpl
sh clusters-binding.tmpl
sh clusters-placement.tmpl
