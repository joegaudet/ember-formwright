import { modifier } from 'ember-modifier'

/**
 * Gives each section heading (h2, h3 with an id) a link to itself, so a section can be shared,
 * then scrolls to the heading `hash` names. Pages render after the browser has already tried
 * the hash, so without this a link like `changesets.md#setup` lands at the top.
 */
export function linkHeadings(element: HTMLElement, hash: string): void {
  for (const heading of element.querySelectorAll<HTMLElement>('h2[id], h3[id]')) {
    if (heading.querySelector('a.heading-anchor')) continue
    const link = document.createElement('a')
    link.className = 'heading-anchor'
    link.href = `#${heading.id}`
    link.setAttribute('aria-label', `Link to “${heading.textContent?.trim()}”`)
    link.textContent = '#'
    heading.append(link)
  }
  const id = decodeURIComponent(hash.slice(1))
  if (id) element.querySelector(`[id="${CSS.escape(id)}"]`)?.scrollIntoView()
}

/** Runs once the page's prose is in the DOM. */
export const headingAnchors = modifier((element: HTMLElement) => {
  linkHeadings(element, window.location.hash)
})
