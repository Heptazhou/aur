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

const PACKAGER = "Heptazhou <zhou@0h7z.com>"
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
const ACT_GH(cmd::String, envs::Pair...) = ODict(
	S"run" => cmd,
	S"env" => ODict(envs...,
		S"GH_REPO"  => S"${{ github.repository }}",
		S"GH_TOKEN" => S"${{ secrets.PAT }}",
	),
)
const ACT_SYNC(pkgbase::String) = ODict(
	# https://github.com/Heptazhou/github-sync
	S"uses" => S"heptazhou/github-sync@v2.3.0",
	S"with" => ODict(
		S"source_repo"        => Symbol("https://aur.archlinux.org/$pkgbase.git"),
		S"source_branch"      => S"master",
		S"destination_branch" => Symbol(pkgbase),
		S"github_token"       => S"${{ secrets.PAT }}",
	),
)

const JOB_MAKE(pkgbases::Vector{String}, tag::String) = ODict(
	S"container" => S"archlinux:base-devel",
	S"runs-on" => S"ubuntu-latest",
	S"steps" => [
		S"run" .=> [
			S"pacman-key --init"
			S"pacman -Syu --noconfirm dbus-daemon-units git github-cli"
		]
		ACT_CHECKOUT.(sort(pkgbases))
		S"run" .=> [
			"""
			makepkg --version
			sed -re 's/\\b(EUID) *== *0\\b/\\1 < -0/g' -i /bin/makepkg
			sed -re 's/^#(MAKEFLAGS)=.*\$/\\1="-j`nproc`"/g' \
				-re 's/^#(PACKAGER)=.*\$/\\1="$PACKAGER"/g' \
			 -i /etc/makepkg.conf"""
			map(pkgbase -> strip("""
			cd $pkgbase
			git rev-parse HEAD | tee ../head
			makepkg -si --noconfirm
			mv -vt .. *.pkg.tar.zst
			"""), pkgbases)
			S"ls -lav *.pkg.tar.zst"
		]
		ACT_ARTIFACT("*.pkg.tar.zst")
		ACT_GH("""
			gh --version
			gh release delete \$GH_TAG --cleanup-tag -y || true
			gh release create \$GH_TAG *.pkg.tar.zst --target `cat head` \
			&& cat head""",
			S"GH_TAG" => Symbol(tag),
		)
	],
)
const JOB_SYNC(pkgbase::String) = ODict(
	S"runs-on" => S"ubuntu-latest",
	S"steps"   => [ACT_CHECKOUT(), ACT_SYNC(pkgbase)],
)

function makepkg(pkgbases::Vector{String}, v::String)
	p = pkgbases[end]
	f = ".github/packages/$p/version.txt"
	mkpath(dirname(f))
	write(f, "$p-v$v", "\n")
	write(".github/workflows/make-$p.yml",
		yaml(
			S"on" => ODict(
				S"workflow_dispatch" => nothing,
				S"push" => ODict(
					S"branches" => ["master"],
					S"paths"    => [f],
				),
			),
			S"jobs" => ODict(
				S"makepkg" => JOB_MAKE(pkgbases, "$p-v$v"),
			),
		),
	)
end
function syncpkg(pkgbases::Vector{String})
	p = s -> isdigit(s[begin]) ? Symbol(:_, s) : Symbol(s)
	f = ".github/workflows/repo-sync.yml"
	mkpath(dirname(f))
	write(f,
		yaml(
			S"on" => ODict(
				S"workflow_dispatch" => nothing,
				S"push" => ODict(
					S"branches" => ["master"],
					S"paths"    => [f],
				),
				S"schedule" => [ODict(S"cron" => "0 */4 * * *")],
			),
			S"jobs" => ODict(
				p(pkgbase) => JOB_SYNC(pkgbase) for pkgbase ∈ pkgbases
			),
		),
	)
end

# https://aur.archlinux.org/packages
const dict = ODict(
	["7-zip-full"]             => (1, 1, "23.01-4"),
	["conda-zsh-completion"]   => (1, 0, "0.11-1"),
	["glibc-linux4"]           => (1, 0, "2.38-1"),
	["iraf-bin"]               => (1, 1, "2.17.1-4"),
	["libcurl-julia-bin"]      => (1, 1, "1.10-1"),
	["locale-mul_zz"]          => (1, 0, "2.0-3"),
	["mingw-w64-zlib", "nsis"] => (1, 1, "3.09-1"),
	["wine-wow64"]             => (1, 0, "9.5-1"),
	["wine64"]                 => (0, 1, "9.5-1"),
	["xgterm-bin"]             => (1, 0, "2.1-2"),
	["yay"]                    => (1, 1, "12.3.5-1"),
)
for (k, v) ∈ filter((k, v)::Pair -> Bool(v[2]), dict)
	makepkg(k, v[3])
end
syncpkg(sort!(reduce(∪, findall(Bool ∘ first, dict))))

