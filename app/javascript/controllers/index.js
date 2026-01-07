import { application } from "controllers/application"

import FlashController from "controllers/flash_controller"
application.register("flash", FlashController)

import MapController from "controllers/map_controller"
application.register("map", MapController)

import GeocodingController from "controllers/geocoding_controller"
application.register("geocoding", GeocodingController)

import SortableController from "controllers/sortable_controller"
application.register("sortable", SortableController)

import ScrollController from "controllers/scroll_controller"
application.register("scroll", ScrollController)

import HelloController from "controllers/hello_controller"
application.register("hello", HelloController)