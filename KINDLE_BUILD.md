# Budowanie wersji testowej na Kindle

Głównym źródłem treści pozostaje `THE IMMERSION GAP.md`. Generator tworzy z niego reflowable EPUB 3 odpowiedni do sprawdzania w Kindle Previewer oraz do prywatnych testów na urządzeniu Kindle.

## Pierwsza konfiguracja

Uruchom jednorazowo:

```powershell
.\setup-pandoc.cmd
```

Skrypt pobiera oficjalną przenośną wersję Pandoca 3.11, sprawdza sumę SHA-256 i zapisuje program lokalnie w `.tools`. Nie wymaga uprawnień administratora ani zmiany systemowej polityki PowerShella.

## Budowanie po każdej zmianie tekstu

Uruchom:

```powershell
.\build-kindle.cmd
```

Gotowy plik powstanie tutaj:

```text
dist\the-immersion-gap.epub
```

Generator automatycznie:

- dodaje `frontpage.png` jako okładkę;
- pobiera tytuł, autora, język, opis i prawa z `ebook.yaml`;
- tworzy stronę tytułową i stronę praw autorskich;
- generuje klikalny spis treści z nagłówków poziomu pierwszego;
- rozdziela wprowadzenie, rozdziały, zakończenie i bibliografię na osobne dokumenty EPUB;
- stosuje typografię z `kindle.css`;
- sprawdza ciągłość numeracji rozdziałów;
- waliduje podstawową strukturę EPUB, metadane, okładkę, kolejność czytania i poprawność XHTML.

Ręczny spis treści umieszczony na początku pliku Markdown jest przydatny podczas redakcji, ale nie trafia do ebooka. W EPUB-ie Pandoc generuje nowy spis bezpośrednio z aktualnych nagłówków, więc odsyłacze nie powinny się zdezaktualizować.

## Pliki, które można edytować

- `THE IMMERSION GAP.md` — treść książki;
- `frontpage.png` — okładka;
- `ebook.yaml` — metadane wydawnicze;
- `ebook-frontmatter.md` — prawa autorskie i nota;
- `kindle.css` — wygląd ebooka.

Nie należy ręcznie edytować `.build`, `.tools` ani `dist`. Są to katalogi robocze lub wynikowe i zostały wyłączone z Gita.

## Przed finalną publikacją

Wersję wynikową należy obejrzeć przynajmniej w Kindle Previewer na kilku symulowanych urządzeniach i rozmiarach czcionki. Przed publikacją trzeba także ponownie sprawdzić metadane, notę prawną, bibliografię, działanie nawigacji oraz finalną rozdzielczość okładki.

