// For apps still using loose-mode (.hbs) templates: add this to your Glint registry.
import type Form from './components/form.gts'

export default interface FormwrightRegistry {
  Form: typeof Form
}
