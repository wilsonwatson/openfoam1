module OpenFOAM
# Adapted from https://github.com/xu-xianghua/ofpp/blob/master/Ofpp/field_parser.py

"""
Input: list of lines, first line index to parse, last 
       line index
Output: Either vector of vectors of floats or vector of floats
"""
function parse_data_nonuniform(content, n, n2)
    num = parse(Int, content[n+1])
    if occursin("scalar", content[n])
        return map(x -> parse(Float64, x), content[n + 3: n + 3 + num])
    else
        return filter(y -> length(y) > 0, map(x -> map(z -> parse(Float64, z), split(strip(x)[2:end-1])), content[n + 3: n + 3 + num]))
    end
end

"""
Input: line string
Output: Either float or vector of floats
"""
function parse_data_uniform(line)
    if occursin("(", line)
        return map(x -> parse(Float64, x), split(split(split(line, "(")[2], ")")[1]))
    else
        return parse(Float64, strip(split(split(line, "uniform")[2], ";")[1]))
    end
end

"""
Input: file
Output: unstructured parsed internal field
"""
function parse_internal_field(x)
    content = readlines(x)
    for (ln, lc) ∈ enumerate(content)
        if startswith(lc, "internalField")
            if occursin("nonuniform", lc)
                return parse_data_nonuniform(content, ln, length(content))
            else
                return parse_data_uniform(content[ln])
            end
        end
    end
end

end
