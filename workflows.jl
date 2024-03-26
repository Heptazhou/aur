# Copyright (C) 2022-2024 Heptazhou <zhou@0h7z.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

using OrderedCollections: OrderedDict as ODict
using YAML: YAML, yaml

const YAML.yaml(xs...) = join(map(yaml, xs), "\n")
macro S_str(string)
	:(Symbol($string))
end

const ACT_ARTIFACT(pat::String) = ODict(
	S"uses" => S"actions/upload-artifact@v4",
	S"with" => ODict(S"compression-level" => 0, S"path" => pat),
)
const ACT_CHECKOUT(ref::String) = ACT_CHECKOUT(
	S"path" => Symbol(ref),
	S"ref"  => Symbol(ref),
)
const ACT_CHECKOUT(xs::Pair...) = ODict(
	S"uses" => S"actions/checkout@v4",
	S"with" => ODict(S"persist-credentials" => false, xs...),
)
const ACT_SYNC(pkgbase::String) = ODict(
	S"uses" => S"repo-sync/github-sync@v2.3.0",
	S"with" => ODict(
		S"source_repo"        => Symbol("https://aur.archlinux.org/$pkgbase.git"),
		S"source_branch"      => S"master",
		S"destination_branch" => Symbol("$pkgbase"),
		S"github_token"       => S"${{ secrets.PAT }}",
	),
)
const JOB_SYNC(pkgbase::String) = ODict(
	S"runs-on" => S"ubuntu-latest",
	S"steps"   => [ACT_CHECKOUT(), ACT_SYNC(pkgbase)],
)

write(".github/workflows/repo-sync.yml",
	yaml(
		S"on" => ODict(
			S"workflow_dispatch" => nothing,
			S"schedule"          => [ODict(S"cron" => "0 */4 * * *")],
		),
		S"jobs" => ODict([
			Symbol(x) => JOB_SYNC(x) for x ∈ [
				"conda-zsh-completion"
				"glibc-linux4"
				"iraf-bin"
				"libcurl-julia-bin"
				"locale-mul_zz"
				"mingw-w64-zlib"
				"nsis"
				"xgterm-bin"
			]
		]),
	),
)

# https://aur.archlinux.org/packages/nsis
v = ["mingw-w64-zlib", "nsis"]
write(".github/workflows/make-nsis.yml",
	yaml(
		S"on" => ODict(
			S"workflow_dispatch" => nothing,
		),
		S"jobs" => ODict(
			S"make" => ODict(
				S"container" => S"archlinux:base-devel",
				S"runs-on" => S"ubuntu-latest",
				S"steps" => [
					ACT_CHECKOUT.(v);
					S"run" => "pacman-key --init"
					S"run" => "pacman -Syu --noconfirm"
					S"run" => strip(
						"""
						makepkg -V
						sed -ri 's/(EUID) == 0/\\1 < 0/g' /bin/makepkg
						""" * mapreduce(pkg -> """
						cd $pkg
						makepkg -si --noconfirm
						mv -vt .. *.pkg.tar.zst
						cd ..
						""", *, v),
					)
					ACT_ARTIFACT("*.pkg.tar.zst")
				],
			),
		),
	),
)

