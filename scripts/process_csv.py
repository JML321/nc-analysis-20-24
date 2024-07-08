import apache_beam as beam
from apache_beam.options.pipeline_options import PipelineOptions, GoogleCloudOptions, StandardOptions
from apache_beam.io import ReadFromText, WriteToText

print(beam.__version__)

class FilterEvenRows(beam.DoFn):
    def process(self, element, index=beam.DoFn.ElementParam):
        if index % 2 != 0:  # Keep odd-numbered rows (indexing starts from 0)
            yield element

class AddIndex(beam.DoFn):
    def __init__(self):
        self.index = -1

    def process(self, element):
        self.index += 1
        yield self.index, element

def run():
    # Set up the pipeline options
    options = PipelineOptions()
    google_cloud_options = options.view_as(GoogleCloudOptions)
    google_cloud_options.project = 'test-g-vision'  # Replace with your actual project ID
    google_cloud_options.job_name = 'filter-even-rows'
    google_cloud_options.staging_location = 'gs://nc-voter-data/staging'
    google_cloud_options.temp_location = 'gs://nc-voter-data/temp'
    options.view_as(StandardOptions).runner = 'DataflowRunner'

    # Define the pipeline
    p = beam.Pipeline(options=options)

    # Read, process, and write the data
    (p
     | 'Read CSV' >> ReadFromText('gs://nc-voter-data/nc_voter_files/add-voterfiles/VR_Snapshot_20081104_noquotes_processed.csv')
     | 'Add Index' >> beam.ParDo(AddIndex())
     | 'Filter Even Rows' >> beam.ParDo(FilterEvenRows())
     | 'Remove Index' >> beam.Map(lambda kv: kv[1])
     | 'Write CSV' >> WriteToText('gs://nc-voter-data/nc_voter_files/add-voterfiles/VR_Snapshot_20081104_noquotes_processed_cleaned.csv', shard_name_template=''))

    # Run the pipeline
    result = p.run()
    result.wait_until_finish()

if __name__ == '__main__':
    run()
