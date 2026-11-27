from pydantic import BaseModel, Field, ConfigDict

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

    