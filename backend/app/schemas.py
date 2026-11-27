import re

from pydantic import (
    BaseModel,
    Field,
    ConfigDict,
    field_validator,
    model_validator
)

class ClienteCreate(BaseModel):
    model_config = ConfigDict(
        str_strip_whitespace=True,
        extra="forbid"
    )

    razao_social: str = Field(min_length=1)

    nome_fantasia: str | None = None
    cnpj: str | None = None

    #Contato
    nome_contato: str | None = None
    telefone: str | None = None
    email: str | None = None

    #Endereço
    cep: str | None = None
    logradouro: str | None = None
    numero: str | None = None
    complemento: str | None = None
    bairro: str | None = None
    cidade: str | None = None
    uf: str | None = Field(
        default=None,
        min_length=2,
        max_length=2
    )

    observacoes: str | None = None

    @field_validator("cnpj")
    @classmethod
    def validator_cnpj(cls, value: str | None):
        if not value:
            return None
        
        value = re.sub(r"[./-]", "", value).upper()

        if not re.fullmatch(r"[A-Z0-9]{12}[0-9]{2}", value):
            raise ValueError("Formato de CNPJ inválido.")

        return value

    @field_validator("cep")
    @classmethod
    def validator_cep(cls, value: str | None):
        if not value:
            return None
        
        value = value.replace("-", "")

        if not re.fullmatch(r"[0-9]{8}", value):
            raise ValueError("CEP deve possuir 8 dígitos.")

        return value

    @field_validator("uf")
    @classmethod
    def validator_uf(cls, value: str | None):
        if not value:
            return None

        estados = {
            "AC", "AL", "AP", "AM", "BA", "CE",
            "DF", "ES", "GO", "MA", "MT", "MS",
            "MG", "PA", "PB", "PR", "PE", "PI",
            "RJ", "RN", "RS", "RO", "RR", "SC",
            "SP", "SE", "TO"
        }
    
        value = value.upper()

        if value not in estados:
            raise ValueError("UF inválida.")

        return value
