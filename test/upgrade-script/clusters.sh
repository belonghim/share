export MRR=ocp414-416
export SIGNATURE=/data01/temp/mirror/ocp414-416/result/release-signatures/

sh signature.tmpl
sh cluster-version.tmpl
sh clusters-binding.tmpl
