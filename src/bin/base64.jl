using Base64

"""
    base64url_encode(input::AbstractVector{UInt8})

Encode bytes to Base64URL (no padding).
"""
function base64url_encode(input::AbstractVector{UInt8})::String
    encoded = base64encode(input)
    encoded = replace(encoded, "+" => "-", "/" => "_")
    return replace(encoded, "=" => "")
end

"""
    base64url_encode(input::String)

Encode string to Base64URL.
"""
function base64url_encode(input::String)::String
    return base64url_encode(codeunits(input))
end

"""
    base64url_decode(input::String)

Decode Base64URL string back to bytes.
"""
function base64url_decode(input::AbstractString)
    # Voltar para Base64 normal
    normalized = replace(input, "-" => "+", "_" => "/")
    # Adicionar padding se necessário
    rem = length(normalized) % 4
    if rem != 0
        normalized *= repeat("=", 4 - rem)
    end
    return base64decode(normalized)
end

"""
    base64url_decode2string(input::String)

Decode Base64URL string back to original string.
"""
function base64url_decode2string(input::AbstractString)
    return String(base64url_decode(input))
end
