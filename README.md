neovim-ghcid
====================

Provides instant haskell error feedback inside of neovim, via [ghcid][1].
This should be a lot faster than running neomake with ghc-mod, and also a
lot simpler.

[1]: https://github.com/ndmitchell/ghcid

![Obligatory gif][gif]

[gif]:https://github.com/cloudhead/images/raw/master/neovim-ghcid.gif

### Dependencies

  * [neovim][neovim] >= 0.1.5
  * [ghcid][ghcid] >= 0.6.5

[neovim]: https://github.com/neovim/neovim
[ghcid]: https://github.com/ndmitchell/ghcid

### Installation

If you're using vim-plug, then add:

      Plug 'cloudhead/neovim-ghcid'

to your init.vim. Alternatively, copy the files to your .config/nvim
folder.

### Usage

`:Ghcid` runs ghcid inside a neovim terminal buffer and populates the
quickfix list with any errors or warnings.

After every file save, the quickfix list is updated with the output of
ghcid.

`:GhcidKill` kills the ghcid job.

