#include </home/sebp/.asdf/installs/erlang/29.0-rc3/erts-17.0/include/erl_nif.h>
#include <cmark.h>

static ERL_NIF_TERM to_html(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    ErlNifBinary input;

    if (!enif_inspect_binary(env, argv[0], &input))
        return enif_make_badarg(env);

    char* html = cmark_markdown_to_html(
        (const char*)input.data,
        input.size,
        CMARK_OPT_DEFAULT
    );

    if (!html)
        return enif_make_atom(env, "error");

    ERL_NIF_TERM result =
        enif_make_string(env, html, ERL_NIF_LATIN1);

    free(html);

    return result;
}

static ErlNifFunc nif_funcs[] = {
    {"to_html", 1, to_html}
};

ERL_NIF_INIT(md, nif_funcs, NULL, NULL, NULL, NULL)
