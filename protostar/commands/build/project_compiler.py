import json
from pathlib import Path
from typing import List

from starkware.cairo.lang.compiler.preprocessor.preprocessor_error import (
    PreprocessorError,
)
from starkware.cairo.lang.vm.vm_exceptions import VmException
from starkware.starknet.services.api.contract_class import ContractClass
from starkware.starkware_utils.error_handling import StarkException

from protostar.commands.build.build_exceptions import CairoCompilationException
from protostar.protostar_toml.protostar_contracts_section import (
    ProtostarContractsSection,
)
from protostar.protostar_toml.protostar_project_section import ProtostarProjectSection
from protostar.utils.starknet_compilation import StarknetCompiler


class ProjectCompiler:
    def __init__(
        self,
        project_section_loader: ProtostarProjectSection.Loader,
        contracts_section_loader: ProtostarContractsSection.Loader,
    ):
        self._project_section_loader = project_section_loader
        self._contracts_section_loader = contracts_section_loader

    def compile(
        self,
        output_dir: Path,
        cairo_path: List[Path],
        disable_hint_validation: bool,
    ):
        project_section = self._project_section_loader.load()
        contracts_section = self._contracts_section_loader.load()
        include_paths = [str(pth) for pth in [*cairo_path, project_section.libs_path]]
        output_dir.mkdir(exist_ok=True)

        for (
            contract_name,
            contract_paths,
        ) in contracts_section.contract_name_to_paths.items():
            contract = self._compile_contract(
                contract_name,
                contract_paths,
                include_paths,
                disable_hint_validation,
            )

            self._save_compiled_contract(contract, output_dir, contract_name)
            self._save_compiled_contract_abi(contract, output_dir, contract_name)

    @staticmethod
    def _compile_contract(
        contract_name: str,
        contract_paths: List[Path],
        include_paths: List[str],
        disable_hint_validation: bool,
    ) -> ContractClass:
        try:
            return StarknetCompiler(
                include_paths=include_paths,
                disable_hint_validation=disable_hint_validation,
            ).compile_contract(
                *contract_paths,
            )
        except StarknetCompiler.FileNotFoundException as err:
            raise StarknetCompiler.FileNotFoundException(
                message=(
                    err.message
                    + '\nDid you forget to update protostar.toml::["protostar.contracts"]?'
                )
            ) from err
        except (StarkException, VmException, PreprocessorError) as err:
            raise CairoCompilationException(
                f"Protostar couldn't compile '{contract_name}' contract\n{str(err)}"
            ) from err

    @staticmethod
    def _save_compiled_contract(
        contract: ContractClass, output_dir: Path, contract_name: str
    ) -> None:
        with open(
            Path(output_dir, f"{contract_name}.json"), mode="w", encoding="utf-8"
        ) as output_file:
            json.dump(
                contract.Schema().dump(contract),
                output_file,
                indent=4,
                sort_keys=True,
            )
            output_file.write("\n")

    @staticmethod
    def _save_compiled_contract_abi(
        contract: ContractClass, output_dir: Path, contract_name: str
    ) -> None:
        with open(
            Path(output_dir, f"{contract_name}_abi.json"),
            mode="w",
            encoding="utf-8",
        ) as output_abi_file:
            json.dump(contract.abi, output_abi_file, indent=4, sort_keys=True)
            output_abi_file.write("\n")
