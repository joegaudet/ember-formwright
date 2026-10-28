import Application from '@ember/application'
import compatModules from '@embroider/virtual/compat-modules'
import Resolver from 'ember-resolver'
import loadInitializers from 'ember-load-initializers'
import config from 'docs-app/config/environment'
import 'ember-basic-dropdown/styles'
import 'ember-power-select/styles'
import '@ember-formwright/ember/theme.css'
import '@ember-formwright/power-select/theme.css'
import '@ember-formwright/power-calendar/theme.css'
import '@ember-formwright/file-upload/theme.css'
import '@ember-formwright/tiptap/theme.css'
import '@ember-formwright/layouts/layouts.css'
import './styles/app.css'

export default class App extends Application {
  modulePrefix = config.modulePrefix
  podModulePrefix = config.podModulePrefix
  Resolver = Resolver.withModules(compatModules)
}

loadInitializers(App, config.modulePrefix, compatModules)
