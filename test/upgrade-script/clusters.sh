export SIGNATURE=/data01/temp/mirror/ocp414-416/result/release-signatures/
export REPO=ocp4

sh signature.tmpl
sh cv-upstream.tmpl
sh all-binding.tmpl
cat placement-all.yaml
