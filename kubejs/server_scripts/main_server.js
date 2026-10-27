// priority 0
// For Panda's Tree Felling to work with TFC trees and axes, we need to remove all logs from the TFC logging tag so the TFC mechanic doesn't proc.
//ServerEvents.tags('block', event => {
    // Removes every log from logging tag, so Panda's Tree Felling will work with TFC trees and axes.
//   event.removeAll('tfc:logs_that_log')
//})
ServerEvents.recipes(event => {
  event.shaped(
    'minecraft:bucket', // Output item and count
    [
      'IRI', 
      'IBI',  
      ' I '
    ],
    {
      I: '#c:ingots/wrought_iron', // Mapping letters to items
      R: 'tfc:metal/bucket/red_steel',
      B: 'tfc:metal/bucket/blue_steel'
    }
  )
})