{ ts-error-translator-src }:
final: prev:
{
  vimPlugins = prev.vimPlugins // {
    ts-error-translator = final.vimUtils.buildVimPlugin {
      name = "ts-error-translator";
      src = ts-error-translator-src;
    };
  };
}
