{ twoslash-queries-src }:
final: prev:
{
  vimPlugins = prev.vimPlugins // {
    twoslash-queries = final.vimUtils.buildVimPlugin {
      name = "twoslash-queries";
      src = twoslash-queries-src;
    };
  };
}
