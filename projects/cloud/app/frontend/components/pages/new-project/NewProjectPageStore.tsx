import OrganizationStore from '@/stores/OrganizationStore';
import { ApolloClient } from '@apollo/client';
import { makeAutoObservable } from 'mobx';
import {
  CreateProjectDocument,
  CreateProjectMutation,
} from '@/graphql/types';

interface CreateProjectProps {
  isCreatingOrganization: boolean;
  selectedProjectOwner: string;
  onCompleted: (projectSlug: string) => void;
}

class NewProjectPageStore {
  private client: ApolloClient<object>;

  constructor(client: ApolloClient<object>) {
    this.client = client;
    makeAutoObservable(this);
  }

  async createProject(
    isCreatingOrganization: boolean,
    selectedProjectOwner: string | undefined,
    projectName: string,
    organizationName: string,
    onCompleted: (projectSlug: string) => void,
  ) {
    const { errors, data } =
      await this.client.mutate<CreateProjectMutation>({
        mutation: CreateProjectDocument,
        variables: {
          input: {
            accountId: isCreatingOrganization
              ? null
              : selectedProjectOwner!,
            name: projectName,
            organizationName: isCreatingOrganization
              ? organizationName
              : null,
          },
        },
      });
    console.log(errors);
    onCompleted(data?.createProject.slug ?? '');
  }
}

export default NewProjectPageStore;
