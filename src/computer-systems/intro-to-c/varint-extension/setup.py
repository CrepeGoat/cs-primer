# based on https://github.com/adamserafini/zaml/blob/27b2d54ffb39aace5d5d58f0aa75396c3e6fe84d/setup.py

import os
from setuptools import setup, Extension
from setuptools.command.build_ext import build_ext


class ZigBuilder(build_ext):
    def build_extension(self, ext):
        assert len(ext.sources) == 2

        deps = [os.path.abspath(s) for s in ext.sources[1:]]
        deps_names = [os.path.splitext(os.path.basename(s))[0] for s in deps]

        if not os.path.exists(self.build_lib):
            os.makedirs(self.build_lib)
        self.spawn(
            [
                "zig",
                "build-lib",
                f"-femit-bin={self.get_ext_fullpath(ext.name)}",
                "-fallow-shlib-undefined",
                "-dynamic",
                *[f"-I{d}" for d in self.include_dirs],
                *[
                    side_source
                    for dep, dep_name in zip(deps, deps_names)
                    for side_source in (
                        "--mod",
                        ":".join([dep_name, "", dep]),
                    )
                ],
                "--deps",
                *deps_names,
                ext.sources[0],
            ]
        )


setup(
    name="cvarint",
    ext_modules=[
        Extension(
            "cvarint",
            sources=[
                "pyvarint.zig",
                os.path.abspath("../../bits-and-bytes/protobuf-varint.zig"),
            ],
        )
    ],
    cmdclass={"build_ext": ZigBuilder},
)
